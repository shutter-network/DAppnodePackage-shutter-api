#!/bin/bash

# To use staker scripts
# shellcheck disable=SC1091
. /etc/profile
# shellcheck disable=SC1091
. "${ASSETS_DIR}/variables.env"

NODE_VERSION=22.14.0
NODE_PACKAGE=node-v$NODE_VERSION-linux-x64
NODE_HOME=/opt/$NODE_PACKAGE

NODE_PATH=$NODE_HOME/lib/node_modules
PATH=$NODE_HOME/bin:$PATH

function test_ethereum_url() {
    # FIXME: This is a workaround for the issue with the staker-scripts@v0.1.1 not setting get_execution_ws_url_from_global_env correctly in the environment variables.
    # Git Issue: https://github.com/dappnode/staker-package-scripts/issues/11
    export SHUTTER_NETWORK_NODE_ETHEREUMURL=${ETHEREUM_WS:-$(get_execution_ws_url_from_global_env ${NETWORK} ${SUPPORTED_NETWORKS})}
    RESULT=$(wscat -c "$SHUTTER_NETWORK_NODE_ETHEREUMURL" -x '{"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}')
    if [[ $RESULT =~ '"id":1' ]]; then return 0; else
        export SHUTTER_NETWORK_NODE_ETHEREUMURL=ws://execution.${NETWORK}.dncore.dappnode:8545
        RESULT=$(wscat -c "$SHUTTER_NETWORK_NODE_ETHEREUMURL" -x '{"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}')
        if [[ $RESULT =~ '"id":1' ]]; then return 0; else
            echo "Could not find DAppNode RPC/WS url for this package!"
            echo "Please configure 'ETHEREUM_WS' to point to an applicable websocket RPC service."
            exit 1
        fi
    fi
}

echo "[INFO | configure] Calculating keyper configuration values..."

SUPPORTED_NETWORKS="gnosis"

# Conditionally add square brackets to SHUTTER_P2P_LISTENADDRESSES
if [[ ! "$SHUTTER_P2P_LISTENADDRESSES" =~ ^\[.*\]$ ]]; then
    export SHUTTER_P2P_LISTENADDRESSES="[$SHUTTER_P2P_LISTENADDRESSES]"
fi

export SHUTTER_P2P_ADVERTISEADDRESSES="[\"/ip4/${_DAPPNODE_GLOBAL_PUBLIC_IP}/tcp/${KEYPER_PORT}\", \"/ip4/${_DAPPNODE_GLOBAL_PUBLIC_IP}/udp/${KEYPER_PORT}/quic-v1\"]"

test_ethereum_url
echo "[DEBUG | configure] SHUTTER_NETWORK_NODE_ETHEREUMURL is ${SHUTTER_NETWORK_NODE_ETHEREUMURL}"

export VALIDATOR_PUBLIC_KEY=$(cat "${SHUTTER_CHAIN_DIR}/config/priv_validator_pubkey.hex")
export SHUTTER_METRICS_ENABLED=${SHUTTER_PUSH_METRICS_ENABLED}
export FLOODSUB_DISCOVERY_ENABLED=true
export SHUTTER_DISCOVERY_NAMESPACE="${_ASSETS_DISCOVERY_NAME_PREFIX}-${_ASSETS_INSTANCE_ID}"

echo "[INFO | configure] LISTEN: $SHUTTER_P2P_LISTENADDRESSES"

# Check if the keyper configuration file already exists
if [ -f "$KEYPER_CONFIG_FILE" ]; then
    echo "[INFO | configure] Keyper configuration file already exists"
else
    echo "[INFO | configure] Generating configuration files..."

    if [ ! -f "$KEYPER_GENERATED_CONFIG_FILE" ]; then
        echo "[ERROR | configure] Missing generated configuration file (${KEYPER_GENERATED_CONFIG_FILE})"
        exit 1
    fi

    cp "$KEYPER_GENERATED_CONFIG_FILE" "$KEYPER_CONFIG_FILE"
fi

go_shutter_settings --generated "$KEYPER_GENERATED_CONFIG_FILE" --config "$KEYPER_CONFIG_FILE" --output "$KEYPER_CONFIG_FILE" include-keyper-settings
