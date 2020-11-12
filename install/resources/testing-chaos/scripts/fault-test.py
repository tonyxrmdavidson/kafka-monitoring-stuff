#!/usr/bin/python3
from subprocess import run
from subprocess import PIPE
import json
from time import sleep
from sys import argv

litmus_ns = ""
prometheus_ns = ""
prometheus_scrape_interval = 0
prometheus_alerts_endpoint = ""

def get_cmd_output(cmd:str) -> (str):
  cmd = cmd.split(" ")
  return run(cmd, stdout=PIPE).stdout.decode("utf-8")

def get_alerts_endpoint(prometheus_ns: str) -> (str):
  global prometheus_alerts_endpoint
  if(prometheus_alerts_endpoint == ""):
    prometheus_route = get_cmd_output(
        "oc get route -n" + prometheus_ns).split("\n")[1].split()[1]
    prometheus_alerts_endpoint = prometheus_route + "/api/v1/alerts"
  return prometheus_alerts_endpoint

def initialise_test_args(args: list):
  global litmus_ns
  global prometheus_ns
  global prometheus_scrape_interval
  global prometheus_alerts_endpoint

  litmus_ns = args[0] if len(args) > 0 else "litmus"
  prometheus_ns = args[1] if len(
      args) > 1 else "managed-services-monitoring-prometheus"
  prometheus_scrape_interval = int(args[2]) if len(args) > 2 else 30
  prometheus_alerts_endpoint = get_alerts_endpoint(prometheus_ns)

def get_engine_names(litmus_ns:str) -> (list):
  names = []
  engines = get_cmd_output("oc get chaosengine -n " + litmus_ns).split("\n")[1:-1]
  for engine in engines:
    names.append(engine.split()[0])
  return names

def is_engine_complete(name:str) -> (bool):
  engine_json = json.loads(get_cmd_output("oc get chaosengine " + name + " -n litmus -o json"))
  experiments = engine_json["status"]["experiments"]
  for experiment in experiments:
    if(experiment["status"] != "Completed"):
      return False
  return True

def is_chaos_complete(engines:list) -> (bool):
  for engine in engines:
    completed = is_engine_complete(engine)
    if(completed != True):
      return False
  return True

def filter_critical_alerts(alerts:list) -> (list):
  critical_alerts = []
  for alert in alerts:
    if(alert["labels"]["severity"] == "critical"):
      critical_alerts.append(alert)
  return critical_alerts  

def get_all_alerts(prometheus_alerts_endpoint:str) -> (list): 
  prometheus_json = json.loads(get_cmd_output("curl -s " + prometheus_alerts_endpoint))
  return prometheus_json["data"]["alerts"]

def get_critical_alerts() -> (list):
  print("Fetching critical alerts...")
  alerts = get_all_alerts(get_alerts_endpoint(prometheus_ns))
  if(len(alerts) == 0):
    return []
  return filter_critical_alerts(alerts)

def watch_alerts() -> (list):
  experiment_complete = is_chaos_complete(get_engine_names(litmus_ns))
  critical_alerts = []
  while(experiment_complete == False):
    print("Waiting {} seconds for next Prometheus scrape interval".format(prometheus_scrape_interval))
    sleep(prometheus_scrape_interval)
    new_alerts = get_critical_alerts()
    print("Alerts scraped. Critical alerts found: {}.".format(new_alerts))
    critical_alerts.extend(new_alerts)
    experiment_complete = is_chaos_complete(get_engine_names(litmus_ns))
  return critical_alerts

def fail_test(critical_alerts:list): 
  print("FAIL: Critical alerts found:\n")
  print(critical_alerts)
  exit(1)

def pass_test():
  print("PASS: No critical alerts found")
  exit(0)

def main():
  initialise_test_args(argv[1:])

  chaos_engines = get_engine_names(litmus_ns)
  if(len(chaos_engines) == 0):
    print("PASS: No chaosengines found")
    exit(0)

  critical_alerts = watch_alerts()

  if(len(critical_alerts) > 0):
    fail_test(critical_alerts)
  pass_test()
  
if __name__== "__main__":
  main()
