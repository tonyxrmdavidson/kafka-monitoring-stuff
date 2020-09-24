# kafka-monitoring-stuff

## Installation

The `install` folder contains resource files and a Makefile to provision a strimzi operator, kafka cluster and our monitoring stack on an openshift cluster.

## Prerequisites

- running OpenShift 4 cluster and kubeadmin credentials
- oc and kubectl binaries
- oc and kubectl logged in to target cluster

## Installing the kafka monitoring demo

Run the `all` target:

```sh
$ make all
```

__NOTE__: the grafana instances are protected via the OpenShift OAuth proxy
__NOTE__: to gain admin access to grafana, login using the credentials from the `grafana-admin-credentials` secret

to uninstall run the `clean` target:

```sh
$ make clean
```

__NOTE__: uninstalling the cluster prometheus namespace can take a few minutes

## Where's what?

The following namespaces are created:

* *kafka-operator*: contains the Strimzi operator
* *kafka-cluster*: contains the Kafka cluster
* *managed-services-monitoring-global*: contains the global monitoring stack including Grafana, Thanos Receiver and Thanos Querier
* *managed-services-monitoring-prometheus*: contains the on cluster Prometheus that scrapes Kafka metrics
* *managed-services-monitoring-grafana*: contains the on cluster Grafana instance

## Installation individual components

Run the targets in the following order:

### Install the strimzi operator

```sh
$ make install/strimzi/operator
```

### Create Kafka Cluster
```sh
$ make install/kafka/cr
```

# Install the global monitoring stack
```sh
$ make install/monitoring/global
```


# Install the cluster monitoring stack
```sh
$ make install/monitoring/cluster
```
