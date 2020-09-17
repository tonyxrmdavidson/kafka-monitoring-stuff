# kafka-monitoring-stuff

## Installation

The `install` folder contains resource files and a Makefile to provision a strimzi operator, kafka cluster and our monitoring stack on an openshift cluster.

### Prerequisites

- running openshift 4 cluster and kubeadmin credentials
- oc and kubectl binaries

### Installation via Makefile

Available `make` targets:

```sh
# install the global monitoring base stack
install/global/monitoring

# install the strimzi operator
install/strimzi/operator

# install monitoring resources for strimzi operator
install/strimzi/monitoring

# install kafka cr
install/kafka/cr

# install monitoring resources for kafka cr
install/kafka/monitoring
```


### Manual installation

If a manual installation is preferred follow the manual steps in `install/installation-guide.md`.