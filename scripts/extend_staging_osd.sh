#!/bin/bash

# This script is used to extend the lifetime of the OSD  staging cluster (used for mas-sso) by 7 days.
# It will be run automatically by a Jenkins job, you should not need to invoke this manually
# Required env vars:
# - OCM_TOKEN: clientToken used by OCM to login to staging environment
# - OSD_STAGE_CLUSTER_ID: the id of the staging cluster to extend lifetime for

set -e

docker pull quay.io/app-sre/mk-ci-tools:latest
docker run -u $(id -u) \
    -e OCM_TOKEN="$OCM_TOKEN" \
	  quay.io/app-sre/mk-ci-tools:latest extend_cluster_lifetime.sh "$OSD_STAGE_CLUSTER_ID"
