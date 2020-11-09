# kafka-monitoring-stuff

This repo has a set of Make targets for the installation and configuration of Kafka in OSD (using Strimzi), and various components to monitor Kafka.
It is intended as a place for hacking things together and dumping any useful stuff until it’s found a more permanent home.

**Not for production use**

## Prerequisites

- A running OpenShift 4 cluster with kubeadmin access
- oc > 4.5 and kubectl > 1.18 binaries, logged in to the OpenShift 4 cluster
- jq installed
- (optional) The strimzi-operator is running in the cluster. Make targets exist to do this as well.
- (optional) A Kafka CR exists & has been reconciled into a running Kafka cluster. Make targets exist to do this as well.

## Terminology

- `in-cluster`, `on-cluster`, `cluster-wide` Refer to things in the same cluster as the Strimzi operator & all the Kafka CRs it's managing
- `global`, `central`, `centralised` Refer to things that are *not* in the same cluster as the Strimzi operator. Typically only 1 instance of these things.

## Installation Options

There are a number of installation options depending on how much of the stack is *already* running in your cluster, and how much you want to *get* running.
The options are available as separate `make` targets from the `install` folder.

```sh
cd install
```

### 1) Install *everything*

**Caution:** You probably don't want to do this. Consider installing just the in-cluster components or just the global components in a single cluster.

The following things will be installed:

* global monitoring components for centralised metrics
* cluster-wide monitoring components, configured to send metrics centrally
* strimzi operator
* strimzi monitoring components to hook into cluster-wide monitoring components
* a kafka cluster

```sh
make all
```

<h3>2) Install <em>global</em> components <em>only</em></h3>

The following things will be installed:

* global monitoring components for centralised metrics

```sh
make install/monitoring/global
```

### 3) Install *in-cluster* components *only*

The following things will be installed:

* cluster-wide monitoring components, configured to send metrics centrally
* strimzi operator
* strimzi monitoring components to hook into cluster-wide monitoring components
* a kafka cluster

```sh
make install/strimzi/operator
make install/monitoring/cluster
make install/kafka/cr
```

### 4) Install *in-cluster* strimzi & kafka components *only* (no monitoring)

The following things will be installed:

* strimzi operator
* a kafka cluster

```sh
make install/strimzi/operator
make install/kafka/cr
```

### 5) Install *in-cluster* monitoring components *only*

This option is useful if you already have a cluster with the strimzi operator running & a Kafka CR.

The following things will be installed:

* cluster-wide monitoring components, configured to send metrics centrally
* strimzi monitoring components to hook into cluster-wide monitoring components


```sh
make install/monitoring/cluster
```

To specify which namespace strimzi & kafka are in, run the cmd with the following vars:

```sh
STRIMZI_OPERATOR_NAMESPACE=my-strimzi-ns KAFKA_CLUSTER_NAMESPACE=my-kafka-ns make install/monitoring/cluster
```

### 6) Install *Observatorium*

You can install observatorium and it's components with:

```sh
make install/observatorium
```

and uninstall it with:

```sh
make uninstall/observatorium
```

#### Pointing the on cluster monitoring stack to observatorium

You can point Prometheus remote write and Promtail to an existing Observatorium instance:

```sh
OBSERVATORIUM_APPS_URL=<e.g. apps-crc.testing> make setup/observatorium
```

This will automatically fetch tokens and update the Prometheus and Promtail configuration

#### Tenant tokens

A default tenant with the name `test` is created. To obtain a token for this tenant:

1) Get the route to the OIDC server:

```
DEX_ROUTE=$(oc get routes dex -ndex -ojsonpath={.spec.host})
```

2) Request a token:

```
curl --request POST \
              --url http://${DEX_ROUTE}/dex/token \
              --header 'content-type: application/x-www-form-urlencoded' \
              --data grant_type=password \
              --data username=admin@example.com \
              --data password=password \
              --data client_id=test \
              --data client_secret=ZXhhbXBsZS1hcHAtc2VjcmV0 \
              --data scope="openid email" | sed 's/^{.*"id_token":[^"]*"\([^"]*\)".*}/\1/'
```

__NOTE__: Observatorium is currently not part of the `all` or `clean` targets.

## Uninstallation

```sh
make clean
```

__NOTE__: uninstalling the cluster prometheus namespace can take a few minutes

## Where's what?

The following namespaces are created:

* *kafka-operator*: contains the Strimzi operator
* *kafka-cluster*: contains the Kafka cluster
* *managed-services-monitoring-global*: contains the global monitoring stack including Grafana, Thanos Receiver and Thanos Querier
* *managed-services-monitoring-prometheus*: contains the on cluster Prometheus that scrapes Kafka metrics
* *managed-services-monitoring-grafana*: contains the on cluster Grafana instance

## Notes

* The Grafana instances are protected by the OpenShift OAuth proxy. Sign in using an OpenShift account with permission to `get` `namespaces`.
* To sign in to Grafana itself (once passed the proxy), use the credentials from the `grafana-admin-credentials` secret in `managed-services-monitoring-grafana` namespace. This is only required if you want to modify dashboards (temporary as dashboards are persisted in GrafanaDashboard CRs & cannot be saved from the Grafana UI)
