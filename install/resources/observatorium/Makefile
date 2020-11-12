export DEX_TOKEN_URL := http://dex-dex.$(OBSERVATORIUM_APPS_URL)
export GATEWAY_URL := https://observatorium-observatorium.$(OBSERVATORIUM_APPS_URL)
export LOG_SCRAPE_NAMESPACES ?= '$(STRIMZI_OPERATOR_NAMESPACE)','$(KAFKA_CLUSTER_NAMESPACE)'
export METRICS_SCRAPE_NAMESPACES ?= '$(STRIMZI_OPERATOR_NAMESPACE)','$(KAFKA_CLUSTER_NAMESPACE)'

.PHONY: create/dex
create/dex:
	@echo "create dex in: $(DEX_NAMESPACE)"
	@sed 's/<namespace>/$(DEX_NAMESPACE)/g' ./dex.yaml | cat | oc apply -f -

.PHONY: create/minio
create/minio:
	@echo "create minio in: $(MINIO_NAMESPACE)"
	@sed 's/<namespace>/$(MINIO_NAMESPACE)/g' ./minio.yaml | cat | oc apply -f -

.PHONY: create/crds
create/crds:
	@oc apply -f ./crd.yaml
	@echo "Waiting for Observatorium CRD to be created"
	@for i in {1..12}; do oc get crd observatoria.core.observatorium.io && break || sleep 5; done

.PHONY: create/operator
create/operator:
	@echo "create observatorium operator in: $(OBSERVATORIUM_NAMESPACE)"
	@sed 's/<namespace>/$(OBSERVATORIUM_NAMESPACE)/g' ./operator.yaml | cat | oc apply -f -
	@ echo "Waiting for observatorium operator to be ready"
	@ for i in {1..12}; do oc -n $(OBSERVATORIUM_NAMESPACE) get pod -l control-plane=observatorium-operator -o name | grep "pod/observatorium-operator" && break || sleep 5; done

.PHONY: create/cr
create/cr:
	@echo "create observatorium in: $(OBSERVATORIUM_NAMESPACE)"
	@sed 's/<namespace>/$(OBSERVATORIUM_NAMESPACE)/g' ./observatorium.yaml | cat | oc apply -f -

.PHONY: create/route
create/route:
	@echo "create route"
	@sed 's/<namespace>/$(OBSERVATORIUM_NAMESPACE)/g' ./route.yaml | cat | oc apply -f -

setup:
	@echo "updating promtail config to point to $(GATEWAY_URL)"
	@cat ../monitoring-cluster/promtail/config.yaml | sed -e 's/<namespace>/$(PER_CLUSTER_GRAFANA_NAMESPACE)/g' | \
		sed -e 's/<name>/$(PER_CLUSTER_PROMTAIL)/g' | \
		sed -e 's/<namespaces>/$(LOG_SCRAPE_NAMESPACES)/g' | \
        sed -e 's/<cluster__id>/$(CLUSTER_ID)/g' | \
        sed -e 's#<gateway>#$(GATEWAY_URL)/api/logs/v1/test/loki/api/v1/push#g' | \
        sed -e 's/<token>/$(shell curl --request POST --url $(DEX_TOKEN_URL)/dex/token --header 'content-type: application/x-www-form-urlencoded' --data grant_type=password --data username=admin@example.com --data password=password --data client_id=test --data client_secret=ZXhhbXBsZS1hcHAtc2VjcmV0 --data scope="openid email" | sed 's/^{.*"id_token":[^"]*"\([^"]*\)".*}/\1/')/g' | \
		cat | oc apply -f -
	@echo "updating prometheus"
	@cat ../monitoring-cluster/prometheus/prometheus-observatorium.yaml | sed -e 's/<namespace>/$(PER_CLUSTER_PROMETHEUS_NAMESPACE)/g' | \
		sed -e 's/<name>/$(PER_CLUSTER_PROMETHEUS)/g' | \
		sed -e 's/<namespaces>/$(METRICS_SCRAPE_NAMESPACES)/g' | \
		sed -e 's/<cluster__id>/$(CLUSTER_ID)/g' | \
        sed -e 's#<gateway>#$(GATEWAY_URL)/api/metrics/v1/test/api/v1/receive#g' | \
        sed -e 's/<token>/$(shell curl --request POST --url $(DEX_TOKEN_URL)/dex/token --header 'content-type: application/x-www-form-urlencoded' --data grant_type=password --data username=admin@example.com --data password=password --data client_id=test --data client_secret=ZXhhbXBsZS1hcHAtc2VjcmV0 --data scope="openid email" | sed 's/^{.*"id_token":[^"]*"\([^"]*\)".*}/\1/')/g' | \
		cat | oc apply -f -
	@echo "updating data sources"
	@cat ../monitoring-cluster/prometheus/datasource.yaml | sed -e 's/<url>/'"$(PER_CLUSTER_PROMETHEUS_NAMESPACE)"'/g' | \
        sed -e 's#<gateway>#$(GATEWAY_URL)#g' | \
        sed -e 's/<tenant>/test/g' | \
        sed -e 's/<token>/$(shell curl --request POST --url $(DEX_TOKEN_URL)/dex/token --header 'content-type: application/x-www-form-urlencoded' --data grant_type=password --data username=admin@example.com --data password=password --data client_id=test --data client_secret=ZXhhbXBsZS1hcHAtc2VjcmV0 --data scope="openid email" | sed 's/^{.*"id_token":[^"]*"\([^"]*\)".*}/\1/')/g' | \
		cat | oc apply -n $(PER_CLUSTER_GRAFANA_NAMESPACE) -f -
	@echo "restarting promtail"
	@oc get pods -n $(PER_CLUSTER_GRAFANA_NAMESPACE) --selector=app=kafka-promtail -oyaml | oc delete -f -

clean:
	@oc delete namespace $(DEX_NAMESPACE)
	@oc delete namespace $(MINIO_NAMESPACE)
	@oc delete namespace $(OBSERVATORIUM_NAMESPACE)
	@echo "Done uninstalling observatorium"

all: create/dex create/minio create/crds create/operator create/cr create/route
	@echo "Done installing observatorium"
