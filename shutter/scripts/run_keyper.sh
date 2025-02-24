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
    $SHUTTER_BIN shutterservicekeyper --config "$KEYPER_CONFIG_FILE"
}

perform_chain_healthcheck

run_keyper
