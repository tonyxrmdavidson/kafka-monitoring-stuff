#!/bin/bash

H0ME_DIRECTORY=$(pwd)
echo "You are in directory $(pwd)"
echo "Logging into openshift cluster"

oc login --server=$OSD_CLUSTER_API --token=$OSD_API_TOKEN --insecure-skip-tls-verify

KAFKA_OPERATOR_NAMESPACE="kafka-operator"
KAFKA_INSTALLED=`oc get ns | grep -c $KAFKA_OPERATOR_NAMESPACE`

if [ $KAFKA_INSTALLED = 0 ]; then
  cd $H0ME_DIRECTORY/install
  echo "You are in directory $(pwd)"
  echo "line 15 reached"
  make all
  sleep 10

  echo "Checking kafka-operator pod status"

  KAFKA_OPERATOR_LABEL_SELECTOR="strimzi-cluster-operator"
  kafka_operator_retry_count=90   # 7 mins 30 seconds
  kafka_operator_min_pods=1

  for (( i=0; i<$kafka_operator_retry_count; i++ )) do
      KAFKA_OPERATOR_POD_RUNNING_COUNT=`oc get pods -n $KAFKA_OPERATOR_NAMESPACE --field-selector=status.phase=Running --selector=name=$KAFKA_OPERATOR_LABEL_SELECTOR | grep -c Running` 
      if [[ $KAFKA_OPERATOR_POD_RUNNING_COUNT -ge kafka_operator_min_pods ]]; then
        echo "KAFKA Operator pod(s) Running"
        break
      elif [[ $((kafka_operator_retry_count - 1)) -eq $i ]]; then
        echo "Kafka operator pod(s) have failed to to reach a running status after 10 mins" 
        exit 1
      fi
      echo "Kafka operator pod(s) are not ready, trying again in 5 seconds"
      sleep 5
  done

  echo "Checking kafka-cluster pods status"

  KAFKA_CLUSTER_NAMESPACE="kafka-cluster"
  KAFKA_LABEL_SELECTOR="my-cluster-kafka"
  EXPORTER_LABEL_SELECTOR="my-cluster-kafka-exporter"
  ZOOKEEPER_LABEL_SELECTOR="my-cluster-zookeeper"
  kafka_cluster_retry_count=150   # 12 mins 30 seconds
  kafka_cluster_min_pods=3
  kafka_exporter_min_pods=1
  kafka_zookeeper_min_pods=3

  for (( i=0; i<$kafka_cluster_retry_count; i++ )) do
      KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT=`oc get pods -n $KAFKA_CLUSTER_NAMESPACE --field-selector=status.phase=Running --selector=strimzi.io/name=$KAFKA_LABEL_SELECTOR | grep -c Running` 
      KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT=`oc get pods -n $KAFKA_CLUSTER_NAMESPACE --field-selector=status.phase=Running --selector=strimzi.io/name=$EXPORTER_LABEL_SELECTOR | grep -c Running`
      KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT=`oc get pods -n $KAFKA_CLUSTER_NAMESPACE --field-selector=status.phase=Running --selector=strimzi.io/name=$ZOOKEEPER_LABEL_SELECTOR | grep -c Running`
      if [[ $KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT -ge kafka_cluster_min_pods && $KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT -ge $kafka_exporter_min_pods && $KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT -ge $kafka_zookeeper_min_pods ]]; then
        echo "$KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT KAFKA cluster pod(s) Running"
        echo "$KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT KAFKA exporter pod(s) Running"
        echo "$KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT KAFKA zoopkeeper pod(s) Running"
        break
      elif [[ $((kafka_cluster_retry_count-1)) -eq $i ]]; then
        echo "Some KAFKA cluster pod(s) have failed to reach a Running phase"
        if [[ $KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT -lt $kafka_cluster_min_pods ]]; then
          echo "There are insufficient KAFKA cluster pods available, $KAFKA_CLUSTER_KAFKA_PODS_RUNNING_COUNT Running"
        fi
        if [[ $KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT -lt $kafka_exporter_min_pods ]]; then  
          echo "There are insufficient KAFKA exporter pods available, $KAFKA_CLUSTER_EXPORTER_PODS_RUNNING_COUNT Running"
        fi
        if [[ $KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT -lt $kafka_zookeeper_min_pods ]]; then  
          echo "There are insufficient KAFKA zookeeper pods available, $KAFKA_CLUSTER_ZOOKEEPER_PODS_RUNNING_COUNT Running"
        fi      
        exit 1
      fi
      echo "Kafka cluster pod(s) are not ready, trying again in 5 seconds"
      sleep 5
  done
fi

if [ $INSTALL_LITMUS = true ]; then
  cd $H0ME_DIRECTORY/install/resources/testing-chaos/
  echo "You are in directory $(pwd)"
  echo "line 79 reached"
  make create/operator/litmus 

  LITMUS_NAMESPACE="litmus"
  CHAOS_SCHEDULER_LABEL_SELECTOR="chaos-scheduler"
  CHAOS_OPERATOR_LABEL_SELECTOR="chaos-operator"
  litmus_retry_count=72   # 6 mins 0 seconds
  litmus_operator_min_pods=1
  litmus_chaos_scheduler_min_pods=1

  echo "checking litmus-operator pod status"

  for (( i=0; i<$litmus_retry_count; i++ )) do
      CHAOS_OPERATOR_POD_RUNNING_COUNT=`oc get pods -n $LITMUS_NAMESPACE --field-selector=status.phase=Running --selector=name=$CHAOS_OPERATOR_LABEL_SELECTOR | grep -c Running` 
      if [[ $CHAOS_OPERATOR_POD_RUNNING_COUNT -ge $litmus_operator_min_pods ]]; then
      # if [[ $CHAOS_OPERATOR_POD_RUNNING_COUNT -ge $itmus_operator_min_pods ]]; then
        echo "Litmus operator pod(s) Running"
        break
      elif [[ $((litmus_retry_count-1)) -eq $i ]]; then
        echo "Litmus chaos-operator pod(s) have failed to to reach a running status after 6 mins"
        echo "There were insufficient LITMUS operator pod(s) available, $CHAOS_OPERATOR_POD_RUNNING_COUNT Running"
        exit 1
      fi
      echo "Litmus operator pod(s) are not ready, trying again in 5 seconds"
      sleep 5
  done

  echo "installing the chaos-scheduler operator"
  make create/operator/chaosscheduler

  echo "checking chaos-scheduler pod status"
  for (( i=0; i<$litmus_retry_count; i++ )) do
      CHAOS_SCHEDULE_POD_RUNING_COUNT=`oc get pods -n $LITMUS_NAMESPACE --field-selector=status.phase=Running --selector=name=$CHAOS_SCHEDULER_LABEL_SELECTOR | grep -c Running` 
      if [[ $CHAOS_SCHEDULE_POD_RUNING_COUNT -ge $litmus_chaos_scheduler_min_pods ]]; then
        echo "Litmus chaos-scheduler pod(s) are Running"
        break
      elif [[ $((litmus_retry_count-1)) -eq $i ]]; then
        echo "Litmus chaos-scheduler pod(s) have failed to to reach a running status after 6 mins"
        exit 1
      fi
      echo "Litmus chaos-scheduler pod(s) are not ready, trying again in 5 seconds"
      sleep 5
  done

  make create/$LITMUS_TEST
fi
