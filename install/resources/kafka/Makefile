.PHONY: create/namespace
create/namespace:
	@echo "create namespace: $(KAFKA_CLUSTER_NAMESPACE)"
	@sed 's/<NAMESPACE>/$(KAFKA_CLUSTER_NAMESPACE)/g' ./namespace.yaml | cat | oc apply -f -

.PHONY: create/kafka
create/kafka:
	@echo "create kafka cluster: $(KAFKA_CLUSTER_NAMESPACE)"
	@cat ./kafka.yaml | sed -e 's/<NAMESPACE>/$(KAFKA_CLUSTER_NAMESPACE)/g' | \
		sed -e 's/<PVC_SIZE>/$(KAFKA_PVC_SIZE)/g' | \
		cat | oc apply -f -

all: create/namespace create/kafka
	@echo "Done installing kafka cr"