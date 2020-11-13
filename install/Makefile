export KAFKA_PVC_SIZE ?= 5Gi

export STRIMZI_OPERATOR_NAMESPACE ?= kafka-operator
export KAFKA_CLUSTER_NAMESPACE ?= kafka-cluster
export KAFKA_CLUSTER_NAME?= my-cluster

export PER_CLUSTER_PROMETHEUS_NAMESPACE ?= managed-services-monitoring-prometheus
export PER_CLUSTER_GRAFANA_NAMESPACE ?= managed-services-monitoring-grafana
export PER_CLUSTER_PROMETHEUS ?= kafka-prometheus
export PER_CLUSTER_PROMTAIL ?= kafka-promtail

export GLOBAL_MONITORING_NAMESPACE ?= managed-services-monitoring-global
export GLOBAL_THANOS_RECEIVER ?= kafka-thanos-receiver
export GLOBAL_THANOS_QUERIER ?= kafka-thanos-querier
export GLOBAL_GRAFANA ?= kafka-grafana-global
export GLOBAL_LOKI ?= kafka-loki-global

export LOGS_MAX_AGE ?= 1d
export LOGS_STORAGE ?= 60G

# Observatorium vars
export DEX_NAMESPACE = dex
export MINIO_NAMESPACE = observatorium-minio
export OBSERVATORIUM_NAMESPACE ?= observatorium
export OBSERVATORIUM_APPS_URL ?= apps.example.io

export CLUSTER_ID ?= $(shell oc get clusterversion -o jsonpath='{.items[].spec.clusterID}{"\n"}')

# kafka listener vars
export KAFKA_CLUSTER_DOMAIN_NAME ?= $(shell oc get --namespace openshift-ingress-operator ingresscontrollers/default --output jsonpath='{.status.domain}{"\n"}')
export KAFKA_UUID ?= $(shell uuidgen | tr '[:upper:]' '[:lower:]')

RESOURCE_FILES_DIR ?= ./resources
BUILD_DIR := build

.PHONY: install/monitoring/cluster
install/monitoring/cluster:
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
	@make -C resources/monitoring-cluster/dashboards all
	@make -C resources/monitoring-cluster/promtail all

  	# cleanup
	@ rm -rf ./$(BUILD_DIR)

.PHONY: uninstall/monitoring/cluster
uninstall/monitoring/cluster:
	@oc delete namespace $(PER_CLUSTER_PROMETHEUS_NAMESPACE)
	@oc delete namespace $(PER_CLUSTER_GRAFANA_NAMESPACE)
	@echo "completed uninstallation of cluster monitoring stack"

.PHONY: install/strimzi/operator
install/strimzi/operator:
	make -C resources/operator all

.PHONY: uninstall/strimzi/operator
uninstall/strimzi/operator:
	@oc delete namespace $(STRIMZI_OPERATOR_NAMESPACE)
	@echo "completed uninstallation of strimzi operator"

.PHONY: install/kafka/cr
install/kafka/cr:
	make -C resources/kafka all

.PHONY: uninstall/kafka/cr
uninstall/kafka/cr:
	@oc delete namespace $(KAFKA_CLUSTER_NAMESPACE)
	@echo "completed uninstallation of kafka cluster"

.PHONY: install/monitoring/global
install/monitoring/global:
	make -C resources/monitoring-global all

.PHONY: install/logging
install/logging:
	make -C resources/logging all

.PHONY: uninstall/logging
uninstall/logging:
	make -C resources/logging clean

.PHONY: uninstall/monitoring/global
uninstall/monitoring/global:
	make -C resources/monitoring-global uninstall

.PHONY: install/observatorium
install/observatorium:
	make -C resources/observatorium all

.PHONY: uninstall/observatorium
uninstall/observatorium:
	make -C resources/observatorium clean

.PHONY: test/chaos
test/chaos:
	make -C resources/testing-chaos all

.PHONY: setup/observatorium
setup/observatorium:
	make -C resources/observatorium setup

all: install/strimzi/operator install/kafka/cr install/monitoring/global install/monitoring/cluster
	@echo "done installing kafka monitoring demo"

clean: uninstall/kafka/cr uninstall/strimzi/operator uninstall/monitoring/global uninstall/monitoring/cluster
	@echo "done uninstalling kafka monitoring demo"