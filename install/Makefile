STRIMZI_OPERATOR_NAMESPACE ?= openshift-operators
KAFKA_CLUSTER_NAMESPACE ?= openshift-kafka-cluster
PER_CLUSTER_MONITORING_NAMESPACE ?= kafka-monitoring-cluster
GLOBAL_MONITORING_NAMESPACE ?= kafka-monitoring-global
RESOURCE_FILES_DIR ?= ./resources
BUILD_DIR := build

.PHONY: install/global/monitoring
install/global/monitoring:

.PHONY: install/strimzi/operator
install/strimzi/operator:
	@ echo "creating deploy files..."
	@ wget https://operatorhub.io/install/strimzi-kafka-operator.yaml -P ./$(BUILD_DIR)
	@ sed -i 's/namespace: .*/namespace: $(STRIMZI_OPERATOR_NAMESPACE)/' ./$(BUILD_DIR)/strimzi-kafka-operator.yaml
	@ sed -i 's/source: .*/source: community-operators/' ./$(BUILD_DIR)/strimzi-kafka-operator.yaml
	@ sed -i 's/sourceNamespace: .*/sourceNamespace: openshift-marketplace/' ./$(BUILD_DIR)/strimzi-kafka-operator.yaml

	@ echo "deploying strimzi operator to $(STRIMZI_OPERATOR_NAMESPACE) namespace..."
	#@ kubectl create ns $(STRIMZI_OPERATOR_NAMESPACE)
	@ oc apply -f ./$(BUILD_DIR)/ 

	@ echo "cleaning up deployment files..."
	@ rm -rf ./$(BUILD_DIR)

.PHONY: install/strimzi/monitoring
install/strimzi/monitoring:

.PHONY: install/kafka/cr
install/kafka/cr:

.PHONY: install/kafka/monitoring
install/kafka/monitoring:

.PHONY: install/kafka/global
install/kafka/global:
	make -C resources/global all