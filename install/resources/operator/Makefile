.PHONY: create/namespace
create/namespace:
	@echo "create namespace: $(STRIMZI_OPERATOR_NAMESPACE)"
	@sed 's/<NAMESPACE>/$(STRIMZI_OPERATOR_NAMESPACE)/g' ./namespace.yaml | cat | oc apply -f -

.PHONY: create/operatorgroup
create/operatorgroup:
	@echo "create operatorgroup: $(STRIMZI_OPERATOR_NAMESPACE)"
	@cat ./operatorgroup.yaml | sed -e 's/<NAMESPACE>/$(STRIMZI_OPERATOR_NAMESPACE)/g' | \
		cat | oc apply -f -

.PHONY: create/subscription
create/subscription:
	@echo "create subscription: $(STRIMZI_OPERATOR_NAMESPACE)"
	@cat ./subscription.yaml | sed -e 's/<NAMESPACE>/$(STRIMZI_OPERATOR_NAMESPACE)/g' | \
		cat | oc apply -f -

all: create/namespace create/operatorgroup create/subscription
	@echo "Waiting for Kafka CRD to be created"
	@for i in {1..12}; do oc get crd kafkas.kafka.strimzi.io && break || sleep 5; done
	@echo "Done installing strimzi-kafka-operator"
