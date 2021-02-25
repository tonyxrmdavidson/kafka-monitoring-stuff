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

export OBSERVABILITY_NAMESPACE ?=kafka-observability
export OBSERVABILITY_RESOURCES_GH ?=https://api.github.com/repos/bf2fc6cc711aee1a0c2a/observability-resources-mk/contents
export ACCESS_TOKEN ?=anaccesstoken
export DEX_PASSWORD ?=dex-password
export DEX_SECRET ?=dex-secret
export DEX_USERNAME ?=dex-username

DEX_P_B := $(shell echo ${DEX_PASSWORD} | base64)
DEX_S_B := $(shell echo ${DEX_SECRET} | base64)
DEX_U_B := $(shell echo ${DEX_USERNAME} | base64)

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

.PHONY: install/observability
install/observability:
	@ mkdir -p ./$(BUILD_DIR)/observability-operator

	@ cp $(RESOURCE_FILES_DIR)/observability-operator/secrets.yaml ./$(BUILD_DIR)/observability-operator/
	@ sed -i 's/<DEX_PASSWORD>/$(DEX_P_B)/' ./$(BUILD_DIR)/observability-operator/secrets.yaml
	@ sed -i 's/<DEX_SECRET>/$(DEX_S_B)/' ./$(BUILD_DIR)/observability-operator/secrets.yaml
	@ sed -i 's/<DEX_USERNAME>/$(DEX_U_B)/' ./$(BUILD_DIR)/observability-operator/secrets.yaml	

	@ cp $(RESOURCE_FILES_DIR)/observability-operator/configmap.yaml ./$(BUILD_DIR)/observability-operator/
	@ sed -i 's/<ACCESS_TOKEN>/$(ACCESS_TOKEN)/' ./$(BUILD_DIR)/observability-operator/configmap.yaml
	@ sed -i 's,<OBSERVABILITY_RESOURCES_GH>,$(OBSERVABILITY_RESOURCES_GH),' ./$(BUILD_DIR)/observability-operator/configmap.yaml

	@ cp $(RESOURCE_FILES_DIR)/observability-operator/namespace.yaml ./$(BUILD_DIR)/observability-operator/
	@ sed -i 's/<NAMESPACE>/$(OBSERVABILITY_NAMESPACE)/' ./$(BUILD_DIR)/observability-operator/namespace.yaml

	@ cp $(RESOURCE_FILES_DIR)/observability-operator/catalogue-source.yaml ./$(BUILD_DIR)/observability-operator/
	@ sed -i 's/<NAMESPACE>/$(OBSERVABILITY_NAMESPACE)/' ./$(BUILD_DIR)/observability-operator/catalogue-source.yaml

	@ cp $(RESOURCE_FILES_DIR)/observability-operator/subscription.yaml ./$(BUILD_DIR)/observability-operator/
	@ sed -i 's/<NAMESPACE>/$(OBSERVABILITY_NAMESPACE)/' ./$(BUILD_DIR)/observability-operator/subscription.yaml

	@ cp $(RESOURCE_FILES_DIR)/observability-operator/operatorgroup.yaml ./$(BUILD_DIR)/observability-operator/
	@ sed -i 's/<NAMESPACE>/$(OBSERVABILITY_NAMESPACE)/' ./$(BUILD_DIR)/observability-operator/operatorgroup.yaml

	@oc apply -f ./${BUILD_DIR}/observability-operator/namespace.yaml
	@oc apply -f ./${BUILD_DIR}/observability-operator/configmap.yaml
	@oc apply -f ./${BUILD_DIR}/observability-operator/secrets.yaml
	@oc apply -f ./${BUILD_DIR}/observability-operator/operatorgroup.yaml	
	@oc apply -f ./${BUILD_DIR}/observability-operator/catalogue-source.yaml
	@oc apply -f ./${BUILD_DIR}/observability-operator/subscription.yaml

	@ rm- rf ${BUILD_DIR}

.PHONY: uninstall/observability
uninstall/observability:
	@oc delete observability observability-stack -n $(OBSERVABILITY_NAMESPACE)
	@oc delete project $(OBSERVABILITY_NAMESPACE)

all: install/strimzi/operator install/kafka/cr install/monitoring/global install/observability
	@echo "done installing kafka monitoring demo"

clean: uninstall/kafka/cr uninstall/strimzi/operator uninstall/monitoring/global uninstall/monitoring/cluster
	@echo "done uninstalling kafka monitoring demo"