#!/bin/bash

# shellcheck disable=SC1091
. "${ASSETS_DIR}/variables.env"

if [ ! -f "$SHUTTER_CHAIN_CONFIG_FILE" ]; then
    echo "[ERROR | configure] Missing chain configuration file (${SHUTTER_CHAIN_CONFIG_FILE})"
    exit 1
fi

ASSETS_GENESIS_FILE="/assets/genesis.json"
CHAIN_GENESIS_FILE="${SHUTTER_CHAIN_DIR}/config/genesis.json"

rm "$CHAIN_GENESIS_FILE"
ln -s "$ASSETS_GENESIS_FILE" "$CHAIN_GENESIS_FILE"

export SHUTTER_ADDR_BOOK_STRICT=true
export SHUTTER_P2P_PEX=true
export SHUTTER_PROMETHEUS_LISTEN_ADDR="0.0.0.0:27660"
export SHUTTER_EXTERNAL_ADDRESS="${_DAPPNODE_GLOBAL_PUBLIC_IP}:${CHAIN_PORT}"
export SHUTTER_P2P_LADDR="tcp://0.0.0.0:${CHAIN_PORT}"

# KEYPER_NAME=${KEYPER_NAME:-$(openssl rand -hex 8)}

go_shutter_settings --generated "$SHUTTER_CHAIN_CONFIG_FILE" --output "$SHUTTER_CHAIN_CONFIG_FILE" include-chain-settings

# TODO: Call the go binary

# sed -i "/^seeds =/c\seeds = \"${_ASSETS_SHUTTERMINT_SEED_NODES}\"" "$SHUTTER_CHAIN_CONFIG_FILE"
# sed -i "/^moniker =/c\moniker = \"${KEYPER_NAME}\"" "$SHUTTER_CHAIN_CONFIG_FILE"
# sed -i "/^genesis_file =/c\genesis_file = \"${ASSETS_GENESIS_FILE}\"" "$SHUTTER_CHAIN_CONFIG_FILE"
# sed -i "/^external_address =/c\external_address = \"${_DAPPNODE_GLOBAL_PUBLIC_IP}:${CHAIN_PORT}\"" "$SHUTTER_CHAIN_CONFIG_FILE"
# sed -i "/^addr_book_strict =/c\addr_book_strict = true" "$SHUTTER_CHAIN_CONFIG_FILE"
# sed -i "/^pex =/c\pex = true" "$SHUTTER_CHAIN_CONFIG_FILE"
# if [ "$SHUTTER_PUSH_METRICS_ENABLED" = "true" ]; then
#     sed -i "/^prometheus =/c\prometheus = true" "$SHUTTER_CHAIN_CONFIG_FILE"
#     sed -i "/^prometheus_listen_addr =/c\prometheus_listen_addr = \"0.0.0.0:26660\"" "$SHUTTER_CHAIN_CONFIG_FILE"
# fi
