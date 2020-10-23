# Litmus Fault Injection Testing

This directory contains the resources required to get up and running for fault injection testing using Litmus. 

## Resources

### Litmus operator

All required resources to deploy the Litmus operator are included in the `./operator` directory.

### ChaosExperiments

ChaosExperiment CRDs for all generic Litmus experiments and some kafka-specific ones are in the `./chaosexperiments` directory.

### ChaosEngines

Prebuilt ChaosEngine CRs and associated ServiceAccount resoures are located in the `./chaosengines` directory.

## Setup

The Litmus operator and ChaosExperiment CRs for the experiments you wish to run are required. The following Makefile targets exist to set these up:

```sh
make create/operator
make create/chaosexperiments
```

## Running Experiments

To run an experiment, you need to deploy a `ChaosEngine` resource to your OpenShift cluster. A ChaosEngine will specify the experiments to be executed, and ChaosEngine resource files and an associated ServiceAccount required to run the experiments are located in subdirectories in the `./chaosengines` directory. Makefile targets exist for these;

```sh
make create/chaosengine/<chaosengine-name>
```