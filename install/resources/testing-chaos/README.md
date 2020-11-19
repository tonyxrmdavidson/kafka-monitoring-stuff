# Litmus Fault Injection Testing

This directory contains the resources required to get up and running for fault injection testing using Litmus. 


## Resources

### Litmus operator

All required resources to deploy the Litmus operator are included in the `./litmus` directory.

### ChaosExperiments

ChaosExperiment CRDs for all generic Litmus experiments and some kafka-specific ones are in the `./chaosexperiments` directory.

### ChaosEngines

Prebuilt ChaosEngine CRs and associated ServiceAccount resoures are located in the `./chaosengines` directory.

### ChaosScheduler

All required resources to deploy the ChaosScheduler operator are included in the `./chaosscheduler` directory.

### ChaosSchedules

Prebuilt ChaosSchedule CRs are located in the `./chaosschedules` directory.


## Setup

The Litmus operator and ChaosExperiment CRs for the experiments you wish to run are required. Optionally, if you wish to use Litmus to schedule experiments the ChaosScheduler operator will be required.

### [Required] Litmus operator

```sh
make create/operator/litmus
```

### [Required] ChaosExperiment definitions

```sh
make create/chaosexperiments
```

### [Optional] Chaosscheduler operator

```sh
make create/operator/chaosscheduler
```


## Running Experiments

Single-execution experiments can be run by deploying a `chaosengine` with the experiment configuration. For regular, scheduled experiments a `chaosschedule` containing the experiment can be deployed.

### ChaosEngines

A ChaosEngine will specify the experiment(s) to be executed. The ChaosEngine will require a ServiceAccount with the required permissions to run the experiment(s). 

Sample ChaosEngines are located in subdirectories in the `./chaosengines` directory; to deploy these ChaosEngines:

```sh
#  engine to randomly delete kafka-broker pods
make create/chaosengines/pod-delete-brokers
```

### ChaosSchedules

A ChaosSchedule will specify the experiment(s) to be executed and the schedule on which it will run. The ChaosEngine will require a ServiceAccount with the required permissions to run the experiment(s).

Sample ChaosSchedules be are located in subdirectories in the `./chaosschedules` directory. To deploy these ChaosSchedules:

```sh
#  schedule to randomly delete kafka-broker pods
make create/chaosschedules/pod-delete-brokers

#  schedule to randomly delete zookeeper pods
make create/chaosschedules/pod-delete-zookeeper
```


## Evaluating Experiments

To evaluate the success or failure of chaos experiments you can check the `chaosresult` or whether alerts in prometheus have fired. 

### Chaosresult

A `chaosresult` for each experiment will be created by Litmus. After an experiment completes the status block can be queried for success/ failure of the experiment:

```sh
# get all chaosresults
oc get chaosresult -n litmus

# check status of chaosresult
oc get chaosresult <chaosresult-name> -o json | jq '.status.experimentstatus'
```


### Prometheus alerts

An automated test and make target exist to monitor prometheus for any critical alerts that fire during chaos experiments:

```sh
make test/critical-alerts
```