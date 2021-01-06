#!/bin/bash

echo "Logging into openshift cluster"
oc login --server=$OSD_CLUSTER_API --token=$OSD_API_TOKEN --insecure-skip-tls-verify
cd install
make all
sleep 10
echo "checking kafka-operator pod status"
for (( i=0; i<120; i++ )) do
    KAFKA_POD_RUNNING=`oc get pods -n kafka-operator | grep -c Running` 
    if [[ $KAFKA_POD_RUNNING = 1 ]]; then
      echo "KAFKA Operator pod is Running"
      break
    fi
    sleep 5
done

echo "checking kafka-cluster pods status"

for (( i=0; i<180; i++ )) do
    KAFKA_CLUSTER_PODS_RUNNING=`oc get pods -n kafka-cluster | grep -c Running` 
    if [[ $KAFKA_CLUSTER_PODS_RUNNING = 7 ]]; then
      echo "KAFKA cluster pods are Running"
      break
    fi
    sleep 5
done

cd resources/testing-chaos/

echo "instlling litmus operator"
make create/operator/litmus

echo "checking litmus-operator pod status"

for (( i=0; i<120; i++ )) do
    LITMUS_POD_RUNNING=`oc get pods -n litmus | grep -c Running` 
    if [[ $LITMUS_POD_RUNNING = 1 ]]; then
      echo "Litmus operator pod is Running"
      break
    fi
    sleep 5
done

echo "installing the chaosscheduler operator"
make create/operator/chaosscheduler

echo "checking chaossscheduler pod status"
for (( i=0; i<120; i++ )) do
    LITMUS_POD_RUNNING=`oc get pods -n litmus | grep -c Running` 
    if [[ $LITMUS_POD_RUNNING = 2 ]]; then
      echo "Litmus chaosscheduler pod is Running"
      break
    fi
    sleep 5
done

# make create/chaosschedule/$LITMUS_TEST