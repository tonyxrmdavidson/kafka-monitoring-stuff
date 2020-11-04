export OS_PROMETHEUS_USER := $(shell oc get secrets -n openshift-monitoring grafana-datasources -o 'go-template={{index .data "prometheus.yaml"}}' | base64 --decode | jq -r '.datasources[0].basicAuthUser')
export OS_PROMETHEUS_PASS := $(shell oc get secrets -n openshift-monitoring grafana-datasources -o 'go-template={{index .data "prometheus.yaml"}}' | base64 --decode | jq -r '.datasources[0].basicAuthPassword')
export PROMETHEUS_REMOTE_WRITE_URL ?= http://$(shell oc get routes -n managed-services-monitoring-global kafka-thanos-receiver-route -ojsonpath='{.spec.host}')
export METRICS_SCRAPE_NAMESPACES ?= '$(STRIMZI_OPERATOR_NAMESPACE)','$(KAFKA_CLUSTER_NAMESPACE)'

.PHONY: create/namespace
create/namespace:
	@echo "create namespace: $(PER_CLUSTER_PROMETHEUS_NAMESPACE)"
	@sed 's/<namespace>/$(PER_CLUSTER_PROMETHEUS_NAMESPACE)/g' ./namespace.yaml | cat | oc apply -f -

.PHONY: create/prometheus
create/prometheus:
	@echo "installing prometheus: $(PER_CLUSTER_PROMETHEUS)"
	@cat ./prometheus.yaml | sed -e 's/<namespace>/$(PER_CLUSTER_PROMETHEUS_NAMESPACE)/g' | \
		sed -e 's/<name>/$(PER_CLUSTER_PROMETHEUS)/g' | \
		sed -e 's/<namespaces>/$(METRICS_SCRAPE_NAMESPACES)/g' | \
		sed -e 's/<cluster__id>/$(CLUSTER_ID)/g' | \
        sed -e 's@<receiver>@$(PROMETHEUS_REMOTE_WRITE_URL)@g' | \
		cat | oc apply -f -
	@echo "Waiting for the prometheus operator to be ready"
	@for i in {1..12}; do oc -n $(PER_CLUSTER_PROMETHEUS_NAMESPACE) get pod -l k8s-app=prometheus-operator -o name | grep "pod/prometheus-operator" && break || sleep 5; done

.PHONY: configure/federation
configure/federation:
	@echo "enabling federation of openshift metrics"
	@cat ./federation.yaml | sed -e 's/<user>/'"$(OS_PROMETHEUS_USER)"'/g' | \
		sed -e 's@<pass>@'"$(OS_PROMETHEUS_PASS)"'@g' > additional-scrape-config.yaml
	@oc create secret generic additional-scrape-configs --from-file=additional-scrape-config.yaml --dry-run=client -o yaml | oc apply -n $(PER_CLUSTER_PROMETHEUS_NAMESPACE) -f -
	@rm -f ./additional-scrape-config.yaml

.PHONY: configure/grafana
configure/grafana:
	@echo "creating grafana data souroce"
	@cat ./datasource.yaml | sed -e 's/<url>/'"$(PER_CLUSTER_PROMETHEUS_NAMESPACE)"'/g' | cat | oc apply -n $(PER_CLUSTER_GRAFANA_NAMESPACE) -f -

.PHONY: create/prometheusrules
create/prometheusrules:
	@echo "creating prometheusrules"
	@sed 's/<namespace>/$(PER_CLUSTER_PROMETHEUS_NAMESPACE)/g' ./prometheus-rules.yaml | cat | oc apply -f -

all: create/namespace create/prometheus configure/federation configure/grafana create/prometheusrules
	@echo "finished setup of cluster metrics collection"