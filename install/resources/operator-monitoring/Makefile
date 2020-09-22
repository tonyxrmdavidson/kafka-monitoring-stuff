.PHONY: create/role
create/role:
	@echo "create role: $(STRIMZI_OPERATOR_NAMESPACE)"
	@oc apply -f ./role.yaml -n $(STRIMZI_OPERATOR_NAMESPACE)

.PHONY: create/rolebinding
create/rolebinding:
	@echo "create rolebinding: $(STRIMZI_OPERATOR_NAMESPACE)"
	@oc apply -f ./rolebinding.yaml -n $(STRIMZI_OPERATOR_NAMESPACE)

all: create/role create/rolebinding
	@echo "Done installing strimzi operator monitoring resources"
	