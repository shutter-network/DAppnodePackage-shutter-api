#!/bin/bash

run_promtail() {
    if [[ $SHUTTER_PUSH_LOGS_ENABLED=true ]];
    then
        promtail -log-config-reverse-order -print-config-stderr -config.file /etc/promtail_config.yaml
    else
        tail -f /dev/null
    fi
}

run_promtail
