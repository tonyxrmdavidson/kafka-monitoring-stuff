# Kafka Fleet View

This directory contains the resources for the global kafka monitoring stack. The following resources are set up:

## Thanos receiver

The store for global monitoring data

## Thanos querier

Query frontend for the store, also used by Grafana

## Grafana

Grafana instance for fleet management dashboards

__NOTE__: the credentials for the Grafana instance can be found in the secret `grafana-admin-credentials` in the global monitoring namespace. 