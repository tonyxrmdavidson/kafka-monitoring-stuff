STRIMZI_OPERATOR_NAMESPACE ?= openshift-operators
KAFKA_CLUSTER_NAMESPACE ?= openshift-kafka-cluster
PER_CLUSTER_MONITORING_NAMESPACE ?= managed-services-monitoring
GLOBAL_MONITORING_NAMESPACE ?= managed-services-monitoring-global
KAFKA_PVC_SIZE ?= 10Gi
RESOURCE_FILES_DIR ?= ./resources
BUILD_DIR := build

.PHONY: install/cluster/monitoring
install/cluster/monitoring:
  # create yaml files
	@ mkdir -p ./$(BUILD_DIR)/monitoring-cluster
	@ cp $(RESOURCE_FILES_DIR)/monitoring-cluster/operatorgroup.yaml ./$(BUILD_DIR)/monitoring-cluster/
	@ cp $(RESOURCE_FILES_DIR)/monitoring-cluster/sub.yaml ./$(BUILD_DIR)/monitoring-cluster/
	@ cp $(RESOURCE_FILES_DIR)/monitoring-cluster/grafana.yaml ./$(BUILD_DIR)/monitoring-cluster/
	@ sed -i.bak 's/<PER_CLUSTER_MONITORING_NAMESPACE>/$(PER_CLUSTER_MONITORING_NAMESPACE)/' ./$(BUILD_DIR)/monitoring-cluster/*.yaml
	
	# create namepsace
	@ -oc new-project $(PER_CLUSTER_MONITORING_NAMESPACE)

	# create operatorgroup
	@ oc apply -f ./$(BUILD_DIR)/monitoring-cluster/operatorgroup.yaml

	# create subscription
	@ oc apply -f ./$(BUILD_DIR)/monitoring-cluster/sub.yaml

	@ echo "Waiting for Grafana CRD to be created"
	@ for i in {1..12}; do oc get crd grafanas.integreatly.org && break || sleep 5; done

	# create grafana CR
	@ oc apply -f ./$(BUILD_DIR)/monitoring-cluster/grafana.yaml

	@ echo "Waiting for grafana pod to be ready"
	@ for i in {1..12}; do oc -n $(PER_CLUSTER_MONITORING_NAMESPACE) get pod -l app=grafana -o name | grep "pod/grafana-deployment" && break || sleep 5; done
	@ oc -n $(PER_CLUSTER_MONITORING_NAMESPACE) wait --for=condition=ready pod -l app=grafana

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
	@ echo "creating deploy files..."
	@ wget https://operatorhub.io/install/strimzi-kafka-operator.yaml -P ./$(BUILD_DIR)
	@ sed -i.bak 's/namespace: .*/namespace: $(STRIMZI_OPERATOR_NAMESPACE)/' ./$(BUILD_DIR)/strimzi-kafka-operator.yaml
	@ sed -i.bak 's/source: .*/source: community-operators/' ./$(BUILD_DIR)/strimzi-kafka-operator.yaml
	@ sed -i.bak 's/sourceNamespace: .*/sourceNamespace: openshift-marketplace/' ./$(BUILD_DIR)/strimzi-kafka-operator.yaml

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
	@ sed -i.bak 's/<KAFKA_CLUSTER_NAMESPACE>/$(KAFKA_CLUSTER_NAMESPACE)/' ./$(BUILD_DIR)/kafka.yaml
	@ sed -i.bak 's/<PVC_SIZE>/$(KAFKA_PVC_SIZE)/' ./$(BUILD_DIR)/kafka.yaml

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