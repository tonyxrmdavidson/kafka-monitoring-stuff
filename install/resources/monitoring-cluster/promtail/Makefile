export LOKI_PUSH_URL ?= $(shell oc get routes -n managed-services-monitoring-global kafka-loki-global -ojsonpath='{.spec.host}')
export LOG_SCRAPE_NAMESPACES ?= '$(STRIMZI_OPERATOR_NAMESPACE)','$(KAFKA_CLUSTER_NAMESPACE)'

.PHONY: create/promtail
create/promtail:
	@echo "create promtail: $(PER_CLUSTER_PROMTAIL)"
	@cat ./promtail.yaml | sed -e 's/<namespace>/$(PER_CLUSTER_GRAFANA_NAMESPACE)/g' | \
		sed -e 's/<name>/$(PER_CLUSTER_PROMTAIL)/g' | \
		sed -e 's/<namespaces>/$(LOG_SCRAPE_NAMESPACES)/g' | \
        sed -e 's/<cluster__id>/$(CLUSTER_ID)/g' | \
        sed -e 's/<loki>/$(LOKI_PUSH_URL)/g' | \
		cat | oc apply -f -

all: create/promtail
	@echo "finished setup of cluster promtail"