.PHONY: create/namespaces
create/namespaces:
	@echo "create logging namespaces"
	@cat ./namespaces.yaml | oc apply -f -

.PHONY: create/operatorgroups
create/operatorgroups:
	@echo "create logging operator groups"
	@cat ./operatorgroups.yaml | oc apply -f -

.PHONY: create/subscriptions
create/subscriptions:
	@echo "create logging operator subscriptions"
	@cat ./subscriptions.yaml | oc apply -f -

.PHONY: create/logging
create/logging:
	@echo "create logging for the last $(LOGS_MAX_AGE)"
	@cat ./logging.yaml | sed -e 's/<age>/$(LOGS_MAX_AGE)/g' | \
		sed -e 's/<size>/$(LOGS_STORAGE)/g' | cat | oc apply -f -

all: create/namespaces create/operatorgroups create/subscriptions create/logging
	@echo "completed installation of logging stack"

clean:
	@oc delete -f ./namespaces.yaml
	@echo ""completed uninstallation of logging stack"