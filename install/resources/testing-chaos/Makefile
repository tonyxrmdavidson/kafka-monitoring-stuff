POD_DELETE_APP_LABEL ?= app.kubernetes.io/name=kafka
POD_DELETE_DEPLOYMENT_TYPE ?= statefulset
POD_DELETE_CLEANUP ?= retain
POD_DELETE_DURATION ?= 60
POD_DELETE_INTERVAL ?= 10
POD_DELETE_FORCE ?= false

.PHONY: create/operator
create/operator:
	@echo "create operator: litmus"
	@kubectl apply -f ./operator/litmus-operator-v1.8.2.yaml

.PHONY: create/chaosexperiments
create/chaosexperiments:
	@echo "create chaosexperiments: $(KAFKA_CLUSTER_NAMESPACE)"
	@kubectl apply -f ./chaosexperiments/chaosexperiments-generic.yaml -n $(KAFKA_CLUSTER_NAMESPACE)
	@kubectl apply -f ./chaosexperiments/chaosexperiments-kafka.yaml -n $(KAFKA_CLUSTER_NAMESPACE)

.PHONY: create/chaosengine/pod-delete
create/chaosengine/pod-delete: 
	@echo "create pod-delete: $(KAFKA_CLUSTER_NAMESPACE)"
	@cat ./chaosengines/pod-delete/serviceaccount.yaml | \
		sed -e 's/<namespace>/$(KAFKA_CLUSTER_NAMESPACE)/g' | \
		cat | oc apply -f -

	@cat ./chaosengines/pod-delete/chaosengine.yaml | \
    sed -e 's|<namespace>|$(KAFKA_CLUSTER_NAMESPACE)|g' | \
    sed -e 's|<pod-label>|$(POD_DELETE_APP_LABEL)|g' | \
    sed -e 's|<deployment-type>|$(POD_DELETE_DEPLOYMENT_TYPE)|g' | \
    sed -e 's|<cleanup>|$(POD_DELETE_CLEANUP)|g' | \
    sed -e 's|<chaos-duration>|$(POD_DELETE_DURATION)|g' | \
    sed -e 's|<chaos-interval>|$(POD_DELETE_INTERVAL)|g' | \
    sed -e 's|<force-delete>|$(POD_DELETE_FORCE)|g' | \
    cat > oc apply -f -

all: create/operator create/chaosexperiments create/chaosengine/pod-delete
	@echo "Done deploying chaos experiments"
