#!/bin/bash

perform_chain_healthcheck() {
    echo "[INFO | keyper] Waiting for chain to be healthy..."

    while true; do
        # Perform the health check
        if curl -sf http://localhost:26657/status >/dev/null; then
            echo "[INFO | keyper] Service is healthy. Exiting health check loop."
            break # Exit the loop if the service is healthy
        else
            echo "[INFO | keyper] Service is not healthy yet. Retrying in 30 seconds..."
        fi

        # Wait for the next interval (30 seconds)
        sleep 30
    done
}

run_keyper() {
    if [[ SHUTTER_PUSH_LOGS_ENABLED=true ]];
    then
        $SHUTTER_BIN shutterservicekeyper --config "$KEYPER_CONFIG_FILE" | rotatelogs -n 1 -e -c /tmp/keyper.log 5M
    else
        $SHUTTER_BIN shutterservicekeyper --config "$KEYPER_CONFIG_FILE"
    fi
}

perform_chain_healthcheck

run_keyper
