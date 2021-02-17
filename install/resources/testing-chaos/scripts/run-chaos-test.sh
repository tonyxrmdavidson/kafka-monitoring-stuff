#!/bin/bash

logOutput() {
    while IFS= read -r line; do
        printf '%s %s\n' "[$(date -u +"%Y-%m-%dT%H:%M:%S")]" "$line";
    done
}

[ -z "$OSD_CLUSTER_API" ] || [ -z "$OSD_API_TOKEN" ] && echo 'The OSD_CLUSTER_API or OSD_API_TOKEN parameter(s) are not set in the "managed-kafka-litmus-test-run" pipeline ' && exit 1 

REPO_DIRECTORY=$(pwd)
echo You are in the root directory of $(basename "$PWD")

echo "Logging into openshift cluster"
oc login --server=$OSD_CLUSTER_API --token=$OSD_API_TOKEN --insecure-skip-tls-verify

KAFKA_OPERATOR_NAMESPACE="kafka-operator"
KAFKA_INSTALLED=`oc get ns | grep -c $KAFKA_OPERATOR_NAMESPACE`

if [ $KAFKA_INSTALLED = 0 ]; then
  cd $REPO_DIRECTORY/install
  echo "You are in directory $(pwd)"
 
  make all | logOutput &>> $REPO_DIRECTORY/$LITMUS_RESULTS_DIR/kafka_make_all_stdout_stderr.txt
  sleep 10

  echo "Checking kafka-operator pod status"

  KAFKA_OPERATOR_LABEL_SELECTOR="strimzi-cluster-operator"
  kafka_operator_retry_count=90   # 7 mins 30 seconds
  kafka_operator_min_pods=1

  for (( i=0; i<$kafka_operator_retry_count; i++ )) do
      KAFKA_OPERATOR_POD_RUNNING_COUNT=`oc get pods -n $KAFKA_OPERATOR_NAMESPACE --field-selector=status.phase=Running --selector=name=$KAFKA_OPERATOR_LABEL_SELECTOR | grep -c Running` 
      if [[ $KAFKA_OPERATOR_POD_RUNNING_COUNT -ge kafka_operator_min_pods ]]; then
        echo "KAFKA Operator pod(s) Running"
        break
      elif [[ $((kafka_operator_retry_count - 1)) -eq $i ]]; then
        echo "Kafka operator pod(s) have failed to to reach a running status after 10 mins" 
        exit 1
      fi
      echo "Kafka operator pod(s) are not ready, trying again in 5 seconds"
      sleep 5
  done

  echo "Checking kafka-cluster pods status"

  KAFKA_CLUSTER_NAMESPACE="kafka-cluster"
  KAFKA_LABEL_SELECTOR="my-cluster-kafka"
  EXPORTER_LABEL_SELECTOR="my-cluster-kafka-exporter"
  ZOOKEEPER_LABEL_SELECTOR="my-cluster-zookeeper"
  kafka_cluster_retry_count=150   # 12 mins 30 seconds
  kafka_cluster_min_pods=3
  kafka_exporter_min_pods=1
  kafka_zookeeper_min_pods=3

  for (( i=0; i<$kafka_cluster_retry_count; i++ )) do
      KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT=`oc get pods -n $KAFKA_CLUSTER_NAMESPACE --field-selector=status.phase=Running --selector=strimzi.io/name=$KAFKA_LABEL_SELECTOR | grep -c Running` 
      KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT=`oc get pods -n $KAFKA_CLUSTER_NAMESPACE --field-selector=status.phase=Running --selector=strimzi.io/name=$EXPORTER_LABEL_SELECTOR | grep -c Running`
      KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT=`oc get pods -n $KAFKA_CLUSTER_NAMESPACE --field-selector=status.phase=Running --selector=strimzi.io/name=$ZOOKEEPER_LABEL_SELECTOR | grep -c Running`
      if [[ $KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT -ge kafka_cluster_min_pods && $KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT -ge $kafka_exporter_min_pods && $KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT -ge $kafka_zookeeper_min_pods ]]; then
        echo "$KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT KAFKA cluster pod(s) Running"
        echo "$KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT KAFKA exporter pod(s) Running"
        echo "$KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT KAFKA zoopkeeper pod(s) Running"
        break
      elif [[ $((kafka_cluster_retry_count-1)) -eq $i ]]; then
        echo "Some KAFKA cluster pod(s) have failed to reach a Running phase"
        if [[ $KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT -lt $kafka_cluster_min_pods ]]; then
          echo "There are insufficient KAFKA cluster pods available, $KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT Running"
        fi
        if [[ $KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT -lt $kafka_exporter_min_pods ]]; then  
          echo "There are insufficient KAFKA exporter pods available, $KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT Running"
        fi
        if [[ $KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT -lt $kafka_zookeeper_min_pods ]]; then  
          echo "There are insufficient KAFKA zookeeper pods available, $KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT Running"
        fi      
        exit 1
      fi
      echo "Kafka cluster pod(s) are not ready, trying again in 5 seconds"
      sleep 5
  done
fi

if [ $INSTALL_LITMUS = true ]; then
  cd $REPO_DIRECTORY/install/resources/testing-chaos/
  echo "You are in directory $(pwd)"

  make create/operator/litmus | logOutput &>> $REPO_DIRECTORY/$LITMUS_RESULTS_DIR/litmus_make_operator_stdout_stderr.txt

  LITMUS_NAMESPACE="litmus"
  CHAOS_SCHEDULER_LABEL_SELECTOR="chaos-scheduler"
  CHAOS_OPERATOR_LABEL_SELECTOR="chaos-operator"
  litmus_retry_count=72   # 6 mins 0 seconds
  litmus_operator_min_pods=1
  litmus_chaos_scheduler_min_pods=1
  litmus_deployed_experiment_definitions_min=1
  litmus_chaos_pod_count_min=1

  echo "checking litmus-operator pod status"

  for (( i=0; i<$litmus_retry_count; i++ )) do
      CHAOS_OPERATOR_POD_RUNNING_COUNT=`oc get pods -n $LITMUS_NAMESPACE --field-selector=status.phase=Running --selector=name=$CHAOS_OPERATOR_LABEL_SELECTOR | grep -c Running` 
      if [[ $CHAOS_OPERATOR_POD_RUNNING_COUNT -ge $litmus_operator_min_pods ]]; then
        echo "Litmus operator pod(s) Running"
        break
      elif [[ $((litmus_retry_count-1)) -eq $i ]]; then
        echo "Litmus chaos-operator pod(s) have failed to to reach a running status after 6 mins"
        echo "There were insufficient LITMUS operator pod(s) available, $CHAOS_OPERATOR_POD_RUNNING_COUNT Running"
        exit 1
      fi
      echo "Litmus operator pod(s) are not ready, trying again in 5 seconds"
      sleep 5
  done

  echo "installing the chaos-scheduler operator"
  make create/operator/chaosscheduler | logOutput &>> $REPO_DIRECTORY/$LITMUS_RESULTS_DIR/litmus_make_chaosscheduler_operator_stdout_stderr.txt

  echo "checking chaos-scheduler pod status"
  for (( i=0; i<$litmus_retry_count; i++ )) do
      CHAOS_SCHEDULE_POD_RUNING_COUNT=`oc get pods -n $LITMUS_NAMESPACE --field-selector=status.phase=Running --selector=name=$CHAOS_SCHEDULER_LABEL_SELECTOR | grep -c Running` 
      if [[ $CHAOS_SCHEDULE_POD_RUNING_COUNT -ge $litmus_chaos_scheduler_min_pods ]]; then
        echo "Litmus chaos-scheduler pod(s) are Running"
        break
      elif [[ $((litmus_retry_count-1)) -eq $i ]]; then
        echo "Litmus chaos-scheduler pod(s) have failed to reach a running status after 6 mins"
        exit 1
      fi
      echo "Litmus chaos-scheduler pod(s) are not ready, trying again in 5 seconds"
      sleep 5
  done

  echo "deploying chaos-experiments"
  make create/chaosexperiments | logOutput &>> $REPO_DIRECTORY/$LITMUS_RESULTS_DIR/litmus_make_chaos_experiments_stdout_stderr.txt

  echo "checking chaos experiments have been deployed"
  for (( i=0; i<$litmus_retry_count; i++ )) do
      CHAOS_EXPERIMENT_POD_COUNT=`oc get chaosexperiments -n $LITMUS_NAMESPACE | grep -c -` 
      if [[ $CHAOS_EXPERIMENT_POD_COUNT -ge $litmus_deployed_experiment_definitions_min ]]; then
        echo "Litmus experiments deployed"
        break
      elif [[ $((litmus_retry_count-1)) -eq $i ]]; then
        echo "Litmus experiments have failed to deploy after 6 mins"
        exit 1
      fi
      echo "Litmus experiments are not deployed, trying again in 5 seconds"
      sleep 5
  done

  make create/$LITMUS_TEST | logOutput &>> $REPO_DIRECTORY/$LITMUS_RESULTS_DIR/litmus_make_tests_stdout_stderr.txt
    
  CHAOS_YAML_DIR=$(echo $LITMUS_TEST | awk -F'/' '{print $1}')
  CHAOS_TEST=$(echo $LITMUS_TEST | awk -F'/' '{print $2}')
  echo "Chaos yaml dir: $CHAOS_YAML_DIR"
  echo "Chaos test: $CHAOS_TEST"
  POD_NAME=$(grep -A1 'metadata:' ${CHAOS_YAML_DIR}s/$CHAOS_TEST/$CHAOS_YAML_DIR.yaml | awk '{print $2}' | tail -n 1)
  echo "Broker's pod name to run the experiment: $POD_NAME"

    # Checking at least 1 pod is deployed
    for (( i=0; i<$litmus_retry_count; i++ )) do
        LITMUS_POD_DELETE_RUNNING_COUNT=`oc get pods -n $LITMUS_NAMESPACE --field-selector=status.phase=Running | grep -c $POD_NAME` 
        if [[ $LITMUS_POD_DELETE_RUNNING_COUNT -ge $litmus_pod_delete_count_min ]]; then
          echo "Litmus $POD_NAME pod is running"
          break
        elif [[ $((litmus_retry_count-1)) -eq $i ]]; then
          echo "No chaos $POD_NAME pods has been created after 6 mins"
          echo $(oc get pods -n litmus)
          exit 1
        fi
        echo "No litmus $POD_NAME pod is deployed yet, trying again in 5 seconds..."
        sleep 5
    done

    # Checking all chaos pods finished
    for (( i=0; i<$litmus_retry_count; i++ )) do
        LITMUS_POD_DELETE_COUNT=`oc get pods -n $LITMUS_NAMESPACE | grep -c $POD_NAME` 
        if [[ $LITMUS_POD_DELETE_COUNT -eq '0' ]]; then
          echo "All $POD_NAME pods are finished"
          break
        elif [[ $((litmus_retry_count-1)) -eq $i ]]; then
          echo "Some $POD_NAME pods are not deleted after 6 min"
          echo $(oc get pods -n litmus)
          exit 1
        fi
        echo "Some Litmus $POD_NAME pods are not finished yet, trying again in 5 seconds..."
        sleep 5
    done
fi
