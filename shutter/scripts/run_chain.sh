#!/bin/bash

run_chain() {

    echo "[INFO | chain] Starting chain..."
    if [[ SHUTTER_PUSH_LOGS_ENABLED=true ]];
    then
        $SHUTTER_BIN chain --config "$SHUTTER_CHAIN_CONFIG_FILE" | rotatelogs -n 1 -e -c /tmp/chain.log 5M
    else
        $SHUTTER_BIN chain --config "$SHUTTER_CHAIN_CONFIG_FILE"
    fi
}

run_chain
