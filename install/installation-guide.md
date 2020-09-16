# Monitoring Kafka

A guide to in-cluster view of monitoring multiple Kafka cluster on a single OSD Cluster

## Prerequisites

* An [OSD cluster](https://qaprodauth.cloud.redhat.com/openshift/) with cluster monitoring enabled
  * Ensure that the ```oc``` client is configured for your OSD cluster.
* [Strimzi 0.19.0](https://github.com/strimzi/strimzi-kafka-operator/releases) 
  

## Deploy the Kafka Operator

Installation of Kafka mostly follows the [Strimzi quickstart](https://strimzi.io/docs/operators/latest/quickstart.html) guide.

Download the latest version of [strimzi-kafka-operator](https://github.com/strimzi/strimzi-kafka-operator/releases).

Note: The following commands assume your current working directory is ```<path-where-you-extracted>strimzi/strimzi-0.19.0```

Create the namespace for the Kafka operator.

NOTE: the namespace must be prefixed with `openshift-` in order to allow it cluster monitoring to detect and monitoring resources.

    oc create namespace <OPERATOR_NAMESPACE>
    sed -i 's/namespace: .*/namespace: <OPERATOR_NAMESPACE>/' install/cluster-operator/*RoleBinding*.yaml

Create a cluster namespace.

Note: the namespace must be prefixed with `openshift-` in order to allow it cluster monitoring to detect and monitoring resources.

oc create namespace <CLUSTER_NAMESPACE>

Add/Edit the project to the list of namespaces which can be watched by the Kafka operators in the deployment template: `strimzi/install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml`

    ...
              env:
            - name: STRIMZI_NAMESPACE
              value: <CLUSTER_NAMESPACE>
    ...

Deploy the Kafka Operator

    oc apply -f install/cluster-operator/ -n <OPERATOR_NAMESPACE>

## Create Kafka cluster(s)

Give the operator permission to watch the project the project namespace

    oc apply -f install/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml -n <CLUSTER_NAMESPACE>
    oc apply -f install/cluster-operator/032-RoleBinding-strimzi-cluster-operator-topic-operator-delegation.yaml -n <CLUSTER_NAMESPACE>
    oc apply -f install/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml -n <CLUSTER_NAMESPACE>

Note: The following commands assume your current working directory is ```<path-where-you-extracted-resources>monitoring-kafka-resources```

Once the Kafak operator is running, create a Kafka cluster.

    oc apply -f resources/cluster/kafka.yaml -n <CLUSTER_NAMESPACE>

Create a Kakfa topic

    oc apply -f resources/cluster/kafka-topic.yaml -n <CLUSTER_NAMESPACE>


## Deploy Monitoring

In order to monitoring your projects using the cluster monitoring stack your project must be labelled accordingly.

    oc label namespace <OPERATOR_NAMESPACE> openshift.io/cluster-monitoring=true
    oc label namespace <CLUSTER_NAMESPACE> openshift.io/cluster-monitoring=true

Add the namespaces of you Kakfa cluster to the `resources/operator/strimzi-podmonitor.yaml`

    ...
      namespaceSelector:
        matchNames:
        - <OPERATOR_NAMESPACE>
        - <CLUSTER_NAMESPACE>
    ...


Deploy the podmonitor 

    oc apply -f resources/operator/strimzi-pod-monitor.yaml -n <OPERATOR_NAMESPACE>
    oc apply -f resources/operator/strimzi-pod-monitor.yaml -n <CLUSTER_NAMESPACE>

Create the roles and rolebindings to allow the cluster monitoring stack to get services and pods in the Kafka operator namespace
```
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prometheus-k8s
  namespace: <OPERATOR_NAMESPACE>
rules:
- apiGroups:
  - ""
  resources:
  - services
  - endpoints
  - pods
  verbs:
  - get
  - list
  - watch
EOF
```
```
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prometheus-k8s
  namespace: <OPERATOR_NAMESPACE>
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: prometheus-k8s
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: openshift-monitoring
EOF
```
Create the roles and rolebindings to allow the cluster monitoring stack to get services and pods in the Kafka cluster namespace

```
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prometheus-k8s
  namespace: <CLUSTER_NAMESPACE>
rules:
- apiGroups:
  - ""
  resources:
  - services
  - endpoints
  - pods
  verbs:
  - get
  - list
  - watch
EOF
```
```
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prometheus-k8s
  namespace: <CLUSTER_NAMESPACE>
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: prometheus-k8s
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: openshift-monitoring
EOF
```

## Deploy Grafana

Install deploy Grafana from operator hub. TODO: Create template for Grafana operator deployment

Or

Install Grafana from the integr8ly/grafana-operator/ repo [here](https://github.com/integr8ly/grafana-operator/blob/master/documentation/deploy_grafana.md). 
Follow the manual procedure

oc create namespace <GRAFANA_NAMESPACE>


Note: The following commands assume your current working directory is ```<path-where-you-extracted-resources>monitoring-kafka-resources```

Create a Grafana instance

    oc apply -f resources/grafana/grafana.yaml -n <GRAFANA_NAMESPACE>

Get the `basicAuthPassword` for the prometheus datasource. Easiest way to do this is get it from the cluster grafana datasource configmap.

    oc get secret grafana-datasources -n openshift-monitoring -o 'go-template={{index .data "prometheus.yaml"}}' | base64 --decode

Add/Edit the `basicAuthPassword` to resources/grafana/grafana-datasource.yaml

Create the grafana datasource

    oc apply -f resources/grafana/grafana-datasource.yaml -n <GRAFANA_NAMESPACE>

Deploy the grafana dashboards

Add/Edit the namespace in the dashboards (in the path: ```resources/grafana/grafana-dashboards```) to GRAFANA_NAMESPACE i.e : ```namespace: <GRAFANA_NAMESPACE>```   

    oc apply -f resources/grafana/grafana-dashboards -n <GRAFANA_NAMESPACE>

# Takeaways
 Takeaways for delpoying a Managed Kafka cluster

* All namespaces to contain monitoring CRs (servicemonitors, podmonitors, prometheusrules) must be labelled correclty and named openshift-... in order to use cluster monitoring
* One Grafana must be installed per OSD cluster
* Grafana datasource needs to be configured with authentication details for the cluster monitoring Prometheus
* Upstream example dashboards are configured for the upsteam example Kafka cluster (specific jmx exporter config for Kafka). Changing this config will break dashboards
* Podmonitor needs to be either created in operator namespace and edits for every Kafka cluster namespace or a podmonitor must be created in each Kafka cluster namespace


# Open Questions/Suggestions

* Creating a new phase in the Kafka cluster creation flow, to add the monitoring pieces in one place, rather than adding bit and pieces in various stages. More of a plug and play method. Could be made generic to get the monitoring enabled mostly for any managed service in the OSD
* Grafana should be configured with the cluster prometheus as a Data source. This should be automated given that every OSD cluster will have a different set of credentials for the cluster prometheus. What form of authentication? Basic auth? Token or User name passwords ?
  * Suggestion: Move to a generic certificate based authentication that can easily enabled and configured.
  
  
  