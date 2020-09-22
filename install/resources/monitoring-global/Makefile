.PHONY: create/namespace
create/namespace:
	@echo "create namespace: $(GLOBAL_MONITORING_NAMESPACE)"
	@sed 's/<namespace>/$(GLOBAL_MONITORING_NAMESPACE)/g' ./namespace.yaml | cat | oc apply -f -

.PHONY: create/thanos/receiver
create/thanos/receiver:
	@echo "create thanos receiver: $(GLOBAL_THANOS_RECEIVER)"
	@cat ./thanos-receiver.yaml | sed -e 's/<namespace>/$(GLOBAL_MONITORING_NAMESPACE)/g' | \
		sed -e 's/<name>/$(GLOBAL_THANOS_RECEIVER)/g' | cat | oc apply -f -

.PHONY: create/thanos/querier
create/thanos/querier:
	@echo "create thanos querier: $(GLOBAL_THANOS_RECEIVER)"
	@cat ./thanos-querier.yaml | sed -e 's/<namespace>/$(GLOBAL_MONITORING_NAMESPACE)/g' | \
		sed -e 's/<name>/$(GLOBAL_THANOS_QUERIER)/g' | \
		sed -e 's/<store>/$(GLOBAL_THANOS_RECEIVER)-service/g' | \
		cat | oc apply -f -

.PHONY: create/grafana
create/grafana:
	@echo "create grafana: $(GLOBAL_GRAFANA)"
	@cat ./grafana.yaml | sed -e 's/<namespace>/$(GLOBAL_MONITORING_NAMESPACE)/g' | \
		sed -e 's/<name>/$(GLOBAL_GRAFANA)/g' | \
		sed -e 's/<querier>/$(GLOBAL_THANOS_QUERIER)-service/g' | \
		cat | oc apply -f -

all: create/namespace create/thanos/receiver create/thanos/querier create/grafana
	@echo "Done installing fleet wide monitoring stack"