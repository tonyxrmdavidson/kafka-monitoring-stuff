all:
	@echo "creating kafka cluster dashboards"
	@cat ./strimzi-kafka.yaml | sed -e 's/<namespace>/$(PER_CLUSTER_GRAFANA_NAMESPACE)/g' | cat | oc apply -f -
	@cat ./strimzi-kafka-exporter.yaml | sed -e 's/<namespace>/$(PER_CLUSTER_GRAFANA_NAMESPACE)/g' | cat | oc apply -f -
	@cat ./strimzi-operators.yaml | sed -e 's/<namespace>/$(PER_CLUSTER_GRAFANA_NAMESPACE)/g' | cat | oc apply -f -
	@cat ./strimzi-zookeeper.yaml | sed -e 's/<namespace>/$(PER_CLUSTER_GRAFANA_NAMESPACE)/g' | cat | oc apply -f -
	@cat ./strimzi-kafka-slis.yaml | sed -e 's/<namespace>/$(PER_CLUSTER_GRAFANA_NAMESPACE)/g' | cat | oc apply -f -


