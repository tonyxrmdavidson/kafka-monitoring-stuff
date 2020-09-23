KAFKA_PVC_SIZE ?= 10Gi

export STRIMZI_OPERATOR_NAMESPACE ?= kafka

# export KAFKA_CLUSTER_NAMESPACE ?= openshift-kafka-cluster
export KAFKA_CLUSTER_NAMESPACE ?= kafka

export PER_CLUSTER_PROMETHEUS_NAMESPACE ?= managed-services-monitoring-prometheus
export PER_CLUSTER_GRAFANA_NAMESPACE ?= managed-services-monitoring-grafana
export PER_CLUSTER_PROMETHEUS ?= kafka-prometheus

export GLOBAL_MONITORING_NAMESPACE ?= managed-services-monitoring-global
export GLOBAL_THANOS_RECEIVER ?= kafka-thanos-receiver
export GLOBAL_THANOS_QUERIER ?= kafka-thanos-querier
export GLOBAL_GRAFANA ?= kafka-grafana-global

RESOURCE_FILES_DIR ?= ./resources
BUILD_DIR := build

.PHONY: install/cluster/monitoring
install/cluster/monitoring:
  # create yaml files
	@ mkdir -p ./$(BUILD_DIR)/monitoring-cluster
	@ cp $(RESOURCE_FILES_DIR)/monitoring-cluster/operatorgroup.yaml ./$(BUILD_DIR)/monitoring-cluster/
	@ cp $(RESOURCE_FILES_DIR)/monitoring-cluster/sub.yaml ./$(BUILD_DIR)/monitoring-cluster/
	@ cp $(RESOURCE_FILES_DIR)/monitoring-cluster/grafana.yaml ./$(BUILD_DIR)/monitoring-cluster/
	@ sed -i.bak 's/<PER_CLUSTER_GRAFANA_NAMESPACE>/$(PER_CLUSTER_GRAFANA_NAMESPACE)/' ./$(BUILD_DIR)/monitoring-cluster/*.yaml
	
	# create namepsace
	@ -oc new-project $(PER_CLUSTER_GRAFANA_NAMESPACE)

	# create operatorgroup
	@ oc apply -f ./$(BUILD_DIR)/monitoring-cluster/operatorgroup.yaml

	# create subscription
	@ oc apply -f ./$(BUILD_DIR)/monitoring-cluster/sub.yaml

	@ echo "Waiting for Grafana CRD to be created"
	@ for i in {1..12}; do oc get crd grafanas.integreatly.org && break || sleep 5; done

	# create grafana CR
	@ oc apply -f ./$(BUILD_DIR)/monitoring-cluster/grafana.yaml

	@ echo "Waiting for grafana pod to be ready"
	@ for i in {1..12}; do oc -n $(PER_CLUSTER_GRAFANA_NAMESPACE) get pod -l app=grafana -o name | grep "pod/grafana-deployment" && break || sleep 5; done

	@make -C resources/monitoring-cluster/prometheus all

  # cleanup
	@ rm -rf ./$(BUILD_DIR)

.PHONY: uninstall/cluster/monitoring
uninstall/cluster/monitoring:
	@ -oc delete project $(PER_CLUSTER_MONITORING_NAMESPACE)
	@ -oc delete crd grafanas.integreatly.org
	@ -oc delete crd grafanadatasources.integreatly.org
	@ -oc delete crd grafanadashboards.integreatly.org

.PHONY: install/strimzi/operator
install/strimzi/operator:
	make -C resources/operator all

.PHONY: install/strimzi/monitoring
install/strimzi/monitoring:
	make -C resources/operator-monitoring all

.PHONY: install/kafka/cr
install/kafka/cr:
	make -C resources/kafka all

.PHONY: install/global/monitoring
install/global/monitoring:
	make -C resources/monitoring-global all
