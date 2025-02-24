#!/bin/bash

check_assets() {
    # shellcheck disable=SC1091
    if [[ ! -f ${ASSETS_DIR}/variables.env ]]; then
        echo "[ERROR | configure] Missing variables file (${ASSETS_DIR}/variables)"
        exit 1
    fi
}

generate_keyper_config() {

    # Check if the configuration file already exists
    if [ -f "$KEYPER_GENERATED_CONFIG_FILE" ]; then
        echo "[INFO | configure] Configuration file already exists. Removing it..."
        rm "$KEYPER_GENERATED_CONFIG_FILE"
    fi

    echo "[INFO | configure] Generating configuration files..."

    $SHUTTER_BIN shutterservicekeyper generate-config --output "$KEYPER_GENERATED_CONFIG_FILE"
}

init_keyper_db() {
    echo "[INFO | configure] Waiting for the database to be ready..."

    until pg_isready -h "db.shutter-api-${NETWORK}.dappnode" -p 5432 -U postgres; do
        echo "[INFO | configure] Database is not ready yet. Retrying in 5 seconds..."
        sleep 5
    done

    echo "[INFO | configure] Initializing keyper database..."

    $SHUTTER_BIN shutterservicekeyper initdb --config "$KEYPER_GENERATED_CONFIG_FILE"
}

init_chain() {

    echo "[INFO | configure] Initializing chain..."

    $SHUTTER_BIN chain init --root "${SHUTTER_CHAIN_DIR}" --genesis-keyper "${SHUTTER_GNOSIS_GENESIS_KEYPER}" --blocktime "${SHUTTER_GNOSIS_SM_BLOCKTIME}" --listen-address "tcp://0.0.0.0:${CHAIN_LISTEN_PORT}" --role validator
}

configure_keyper() {

    echo "[INFO | configure] Configuring keyper..."

    "configure_keyper.sh"
}

configure_chain() {

    echo "[INFO | configure] Configuring chain..."

    "configure_shuttermint.sh"
}

trigger_chain_start() {

    echo "[INFO | configure] Triggering chain start..."

    supervisorctl start chain
}

trigger_keyper_start() {

    echo "[INFO | configure] Triggering keyper start..."

    supervisorctl start keyper
}

check_assets

generate_keyper_config

init_keyper_db

configure_keyper

init_chain

configure_chain

trigger_chain_start

trigger_keyper_start