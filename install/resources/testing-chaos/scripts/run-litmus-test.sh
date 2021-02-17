#!/bin/bash

export OSD_CLUSTER_API
export OSD_API_TOKEN
export INSTALL_LITMUS
export LITMUS_TEST

LITMUS_RESULTS_DIR=litmus-results
export LITMUS_RESULTS_DIR

logOutput() {
    while IFS= read -r line; do
        printf '%s %s\n' "[$(date -u +"%Y-%m-%dT%H:%M:%S")]" "$line";
    done
}

mkdir litmus-results
./install/resources/testing-chaos/scripts/run-chaos-test.sh | logOutput |& tee -a $LITMUS_RESULTS_DIR/all_output.txt