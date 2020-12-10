LITMUS_NS ?= litmus
CLUSTER_PROMETHEUS_NS ?= managed-services-monitoring-prometheus
PROMETHEUS_SCRAPE_INTERVAL ?= 30
KAFKA_CLUSTER_NAMESPACE ?= kafka-cluster
KAFKA_CLUSTER_NAME ?= my-cluster
BROKER_POD_LABEL ?= app.kubernetes.io/name=kafka
BROKER_DEPLOYMENT_TYPE ?= statefulset
ZOOKEEPER_POD_LABEL ?= app.kubernetes.io/name=zookeeper
ZOOKEEPER_DEPLOYMENT_TYPE ?= statefulset

CHAOS_SCHEDULE_INCLUDED_DAYS ?= Mon,Tue,Wed,Thu,Fri
CHAOS_SCHEDULE_INCLUDED_HOURS ?= 8-17
CHAOS_SCHEDULE_MIN_INTERVAL ?= 3m
CHAOS_SCHEDULE_STATE ?= active
CHAOS_SCHEDULE_CLEANUP ?= delete

POD_DELETE_CLEANUP ?= delete
POD_DELETE_DURATION ?= 60
POD_DELETE_INTERVAL ?= 10
POD_DELETE_FORCE ?= false

AZ_DOWN_DRY_RUN ?= false

.PHONY: create/operator/litmus
create/operator/litmus:
	@echo "create operator: litmus"
	@kubectl apply -f ./litmus/litmus-operator-v1.8.2.yaml
	@kubectl apply -f ./litmus/serviceaccount.yaml

.PHONY: create/operator/chaosscheduler
create/operator/chaosscheduler: 
	@echo "create operator: chaosscheduler"
	@kubectl apply -f ./chaosscheduler/chaosschedule_crd.yaml
	@kubectl apply -f ./chaosscheduler/chaos-scheduler.yaml
	@kubectl apply -f ./chaosscheduler/chaos-scheduler-sa.yaml

.PHONY: create/chaosexperiments
create/chaosexperiments:
	@echo "create chaosexperiment resources"
	@kubectl apply -f ./chaosexperiments/chaosexperiments-generic.yaml
	@kubectl apply -f ./chaosexperiments/chaosexperiments-kafka.yaml
	@kubectl apply -f ./chaosexperiments/chaosexperiments-az-down.yaml

.PHONY: create/strimzi-traffic-generator
create/strimzi-traffic-generator:
	@echo "create strimzi-traffic-generator: $(KAFKA_CLUSTER_NAMESPACE)"
	@cat ./strimzi-traffic-generator/deployment.yaml | \
    sed -e 's|<namespace>|$(KAFKA_CLUSTER_NAMESPACE)|g' | \
    sed -e 's|<kafka-cluster-name>|$(KAFKA_CLUSTER_NAME)|g' | \
    cat | oc apply -f -

.PHONY: create/chaosschedule/pod-delete-brokers
create/chaosschedule/pod-delete-brokers: 
	@echo "create pod-delete chaosschedule"
	@cat ./chaosschedules/pod-delete-brokers/chaosschedule.yaml | \
    sed -e 's|<chaos-schedule-interval>|$(CHAOS_SCHEDULE_MIN_INTERVAL)|g' | \
    sed -e 's|<chaos-schedule-included-days>|$(CHAOS_SCHEDULE_INCLUDED_DAYS)|g' | \
    sed -e 's|<chaos-schedule-included-hours>|$(CHAOS_SCHEDULE_INCLUDED_HOURS)|g' | \
    sed -e 's|<chaos-schedule-state>|$(CHAOS_SCHEDULE_STATE)|g' | \
    sed -e 's|<namespace>|$(KAFKA_CLUSTER_NAMESPACE)|g' | \
    sed -e 's|<pod-label>|$(BROKER_POD_LABEL)|g' | \
    sed -e 's|<deployment-type>|$(BROKER_DEPLOYMENT_TYPE)|g' | \
    sed -e 's|<cleanup>|$(CHAOS_SCHEDULE_CLEANUP)|g' | \
    sed -e 's|<chaos-duration>|$(POD_DELETE_DURATION)|g' | \
    sed -e 's|<chaos-interval>|$(POD_DELETE_INTERVAL)|g' | \
    sed -e 's|<force-delete>|$(POD_DELETE_FORCE)|g' | \
    cat | oc apply -f -

.PHONY: create/chaosschedule/pod-delete-zookeepers
create/chaosschedule/pod-delete-zookeepers: 
	@echo "create pod-delete chaosschedule"
	@cat ./chaosschedules/pod-delete-zookeepers/chaosschedule.yaml | \
    sed -e 's|<chaos-schedule-interval>|$(CHAOS_SCHEDULE_MIN_INTERVAL)|g' | \
    sed -e 's|<chaos-schedule-included-days>|$(CHAOS_SCHEDULE_INCLUDED_DAYS)|g' | \
    sed -e 's|<chaos-schedule-included-hours>|$(CHAOS_SCHEDULE_INCLUDED_HOURS)|g' | \
    sed -e 's|<chaos-schedule-state>|$(CHAOS_SCHEDULE_STATE)|g' | \
    sed -e 's|<namespace>|$(KAFKA_CLUSTER_NAMESPACE)|g' | \
    sed -e 's|<pod-label>|$(ZOOKEEPER_POD_LABEL)|g' | \
    sed -e 's|<deployment-type>|$(ZOOKEEPER_DEPLOYMENT_TYPE)|g' | \
    sed -e 's|<cleanup>|$(CHAOS_SCHEDULE_CLEANUP)|g' | \
    sed -e 's|<chaos-duration>|$(POD_DELETE_DURATION)|g' | \
    sed -e 's|<chaos-interval>|$(POD_DELETE_INTERVAL)|g' | \
    sed -e 's|<force-delete>|$(POD_DELETE_FORCE)|g' | \
    cat | oc apply -f -

.PHONY: create/chaosengine/pod-delete
create/chaosengine/pod-delete: 
	@echo "create pod-delete chaosengine"
	@cat ./chaosengines/pod-delete-brokers/chaosengine.yaml | \
    sed -e 's|<namespace>|$(KAFKA_CLUSTER_NAMESPACE)|g' | \
    sed -e 's|<pod-label>|$(BROKER_POD_LABEL)|g' | \
    sed -e 's|<deployment-type>|$(BROKER_DEPLOYMENT_TYPE)|g' | \
    sed -e 's|<cleanup>|$(POD_DELETE_CLEANUP)|g' | \
    sed -e 's|<chaos-duration>|$(POD_DELETE_DURATION)|g' | \
    sed -e 's|<chaos-interval>|$(POD_DELETE_INTERVAL)|g' | \
    sed -e 's|<force-delete>|$(POD_DELETE_FORCE)|g' | \
    cat | oc apply -f -

.PHONY: create/chaosengine/az-down
create/chaosengine/az-down: 
	@echo "create az-down chaosengine"
	@cp ./utils/aws_secret_template.yaml ./utils/aws_secret.yaml
	@sed -i 's/<aws-iam-key>/$(AWS_IAM_KEY)/' ./utils/aws_secret.yaml
	@sed -i 's/<aws-iam-secret>/$(AWS_IAM_SECRET)/' ./utils/aws_secret.yaml
	@oc create secret generic cloud-config --from-file=./utils/aws_secret.yaml -n $(LITMUS_NS)

	@cat ./chaosengines/az-down/chaosengine.yaml | \
    sed -e 's|<namespace>|$(KAFKA_CLUSTER_NAMESPACE)|g' | \
    sed -e 's|<pod-label>|$(BROKER_POD_LABEL)|g' | \
    sed -e 's|<deployment-type>|$(BROKER_DEPLOYMENT_TYPE)|g' | \
    sed -e 's|<cleanup>|$(POD_DELETE_CLEANUP)|g' | \
    sed -e 's|<chaos-duration>|$(POD_DELETE_DURATION)|g' | \
    sed -e 's|<chaos-interval>|$(POD_DELETE_INTERVAL)|g' | \
    sed -e 's|<aws-region>|$(AZ_DOWN_REGION)|g' | \
    sed -e 's|<aws-iam-key-id>|$(AZ_DOWN_IAM_KEY)|g' | \
    sed -e 's|<aws-iam-secret>|$(AZ_DOWN_IAM_SECRET)|g' | \
    sed -e 's|<cluster-identifier>|$(AZ_DOWN_CLUSTER_IDENTIFIER)|g' | \
    sed -e 's|<dry-run>|$(AZ_DOWN_DRY_RUN)|g' | \
    cat | oc apply -f -

.PHONY: test/critical-alerts
test/critical-alerts:
	@python3 ./scripts/fault-test.py $(LITMUS_NS) $(CLUSTER_PROMETHEUS_NS) $(PROMETHEUS_SCRAPE_INTERVAL)

.PHONY: uninstall/operator/chaosscheduler
uninstall/operator/chaosscheduler:
	@echo "removing chaosscheduler resources"
	@oc oc delete crd chaosschedules.litmuschaos.io
	@oc delete deployment chaos-scheduler -n litmus
	@oc delete sa scheduler -n litmus
	@oc delete clusterrole scheduler
	@oc delete clusterrolebinding scheduler
	@echo "Done removing chaosscheduler resources"

.PHONY: uninstall/operator/litmus
uninstall/operator/litmus:
	@echo "removing litmus resources"
	@oc delete ns litmus
	@echo "Done removing litmus resources"

all: create/operator/litmus create/chaosexperiments create/operator/chaosscheduler create/strimzi-traffic-generator create/chaosschedule/pod-delete-brokers create/chaosschedule/pod-delete-zookeepers test/critical-alerts
	@echo "Done deploying chaos experiments"
