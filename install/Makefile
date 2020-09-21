STRIMZI_OPERATOR_NAMESPACE ?= openshift-operators
KAFKA_CLUSTER_NAMESPACE ?= openshift-kafka-cluster
PER_CLUSTER_MONITORING_NAMESPACE ?= kafka-monitoring-cluster
GLOBAL_MONITORING_NAMESPACE ?= kafka-monitoring-global
KAFKA_PVC_SIZE ?= 10Gi
RESOURCE_FILES_DIR ?= ./resources
BUILD_DIR := build

.PHONY: install/global/monitoring
install/global/monitoring:
  # create yaml files
	@ rm -rf ./$(BUILD_DIR)/grafana
	@ mkdir -p ./$(BUILD_DIR)/grafana
	@ cp $(RESOURCE_FILES_DIR)/grafana/operatorgroup.yaml ./$(BUILD_DIR)/grafana/
	@ cp $(RESOURCE_FILES_DIR)/grafana/sub.yaml ./$(BUILD_DIR)/grafana/
	@ cp $(RESOURCE_FILES_DIR)/grafana/grafana.yaml ./$(BUILD_DIR)/grafana/
	@ sed -i 's/<PER_CLUSTER_MONITORING_NAMESPACE>/$(PER_CLUSTER_MONITORING_NAMESPACE)/' ./$(BUILD_DIR)/grafana/*.yaml
	
	# create namepsace
	@ oc new-project $(PER_CLUSTER_MONITORING_NAMESPACE)

	# create operatorgroup
	@ oc apply -f ./$(BUILD_DIR)/grafana/operatorgroup.yaml

	# # create subscription
	@ oc apply -f ./$(BUILD_DIR)/grafana/sub.yaml

	# # create grafana CR
	@ oc apply -f ./$(BUILD_DIR)/grafana/grafana.yaml

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
	@ echo "creating deploy files..."
	@ mkdir ./$(BUILD_DIR)
	@ cp $(RESOURCE_FILES_DIR)/cluster/kafka.yaml ./$(BUILD_DIR)
	@ sed -i 's/<KAFKA_CLUSTER_NAMESPACE>/$(KAFKA_CLUSTER_NAMESPACE)/' ./$(BUILD_DIR)/kafka.yaml
	@ sed -i 's/<PVC_SIZE>/$(KAFKA_PVC_SIZE)/' ./$(BUILD_DIR)/kafka.yaml

	@ echo "deploying kafka cluster to $(KAFKA_CLUSTER_NAMESPACE) namespace..."
	@ kubectl create ns $(KAFKA_CLUSTER_NAMESPACE)
	@ oc apply -f ./$(BUILD_DIR)/kafka.yaml
	@ echo "kafka cluster deployed to $(KAFKA_CLUSTER_NAMESPACE) namespace..."

	@ echo "cleaning up deployment files..."
	@ rm -rf ./$(BUILD_DIR)

.PHONY: install/kafka/monitoring
install/kafka/monitoring:

.PHONY: install/kafka/global
install/kafka/global:
	make -C resources/global all