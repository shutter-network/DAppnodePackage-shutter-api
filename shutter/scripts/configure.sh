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

read_announced_validator_key() {

    # go_shutter_settings writes the key as one line, ValidatorPublicKey = '<hex>'. Prints nothing when
    # keyper.toml or the line is missing.
    sed -n "s/^ValidatorPublicKey = '\([^']*\)'$/\1/p" "$KEYPER_CONFIG_FILE" 2>/dev/null
}

warn_if_validator_key_missing() {

    # keyper.toml only exists after an earlier start. If the validator key is gone then (for example after
    # the chain volume was removed), chain init creates a new key instead of using the old one.
    if [ -f "$KEYPER_CONFIG_FILE" ] && [ ! -f "${SHUTTER_CHAIN_DIR}/config/priv_validator_key.json" ]; then
        echo "[WARN | configure] The Shuttermint validator key file is missing, but keyper.toml exists from an earlier start. A new validator key will be created. To keep the previous key, restore chain-config from a backup."
    fi

    PREVIOUS_ANNOUNCED_KEY=$(read_announced_validator_key)
}

warn_if_announced_key_changed() {

    local announced_key

    announced_key=$(read_announced_validator_key)

    if [ -n "$PREVIOUS_ANNOUNCED_KEY" ] && [ "$PREVIOUS_ANNOUNCED_KEY" != "$announced_key" ]; then
        echo "[WARN | configure] The validator public key announced in keyper.toml changed from ${PREVIOUS_ANNOUNCED_KEY} to ${announced_key:-none}."
    fi
}

print_validator_key() {

    local public_key address announced_key

    public_key=$(cat "${SHUTTER_CHAIN_DIR}/config/priv_validator_pubkey.hex" 2>/dev/null)
    address=$(sed -n 's/^ *"address": "\([0-9A-Fa-f]*\)",$/\1/p' "${SHUTTER_CHAIN_DIR}/config/priv_validator_key.json" 2>/dev/null)
    announced_key=$(read_announced_validator_key)

    echo "[INFO | configure] Shuttermint validator public key: ${public_key:-none}"
    echo "[INFO | configure] Shuttermint validator address: ${address:-none}"
    echo "[INFO | configure] Validator public key announced in keyper.toml: ${announced_key:-none}"
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

warn_if_validator_key_missing

# chain init creates or finds the validator key and writes its public key, which configure_keyper reads.
init_chain

configure_keyper

configure_chain

print_validator_key

warn_if_announced_key_changed

trigger_chain_start

trigger_keyper_start