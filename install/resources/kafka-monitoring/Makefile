.PHONY: create/role
create/role:
	@echo "create role: $(KAFKA_CLUSTER_NAMESPACE)"
	@oc apply -f ./role.yaml -n $(KAFKA_CLUSTER_NAMESPACE)

.PHONY: create/rolebinding
create/rolebinding:
	@echo "create rolebinding: $(KAFKA_CLUSTER_NAMESPACE)"
	@oc apply -f ./rolebinding.yaml -n $(KAFKA_CLUSTER_NAMESPACE)

all: create/role create/rolebinding
	@echo "Done installing kafka cluster monitoring resources"
