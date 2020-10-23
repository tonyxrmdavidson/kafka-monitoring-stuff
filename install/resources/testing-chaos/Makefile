.PHONY: create/operator
create/operator:
	@echo "create operator: litmus"
	@kubectl apply -f ./operator/litmus-operator-v1.8.2.yaml

.PHONY: create/chaosexperiments
create/chaosexperiments:
	@echo "create chaosexperiments: $(KAFKA_CLUSTER_NAMESPACE)"
	@kubectl apply -f ./chaosexperiments/chaosexperiments-generic.yaml -n kafka-cluster
	@kubectl apply -f ./chaosexperiments/chaosexperiments-kafka.yaml -n kafka-cluster

.PHONY: create/chaosengine/pod-delete
create/chaosengine/kafka-broker-pod-failure: 
	@echo "create pod-delete: $(KAFKA_CLUSTER_NAMESPACE)"
	@kubectl apply -f ./chaosengines/pod-delete/serviceaccount.yaml
	@kubectl apply -f ./chaosengines/pod-delete/chaosengine.yaml

all: create/operator create/chaosexperiments create/chaosengine/pod-delete
	@echo "Done deploying chaos experiments"
