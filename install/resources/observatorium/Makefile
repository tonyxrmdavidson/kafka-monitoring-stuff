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

clean:
	@oc delete namespace $(DEX_NAMESPACE)
	@oc delete namespace $(MINIO_NAMESPACE)
	@oc delete namespace $(OBSERVATORIUM_NAMESPACE)
	@echo "Done uninstalling observatorium"

all: create/dex create/minio create/crds create/operator create/cr
	@echo "Done installing observatorium"
