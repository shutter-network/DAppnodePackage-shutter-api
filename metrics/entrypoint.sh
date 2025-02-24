#!/bin/sh

update_user_settings() {

    keys="KEYPER_NAME PUSHGATEWAY_URL PUSHGATEWAY_USERNAME PUSHGATEWAY_PASSWORD"

    if [ ! -f "$USER_SETTINGS_FILE" ]; then
        touch "$USER_SETTINGS_FILE"
    fi

    for key in $keys; do
        update_user_setting "$key" "$(eval echo \$"$key")"
    done
}

update_user_setting() {
    key=$1
    value=$(eval echo \$"$key")

    if [ -z "$value" ]; then
        echo "[INFO | metrics] Skipped updating $key in user settings file (empty value)"
        return 0
    fi

    if grep -q "^$key=" "$USER_SETTINGS_FILE"; then
        # Update the existing key
        sed -i "s|^$key=.*|$key=$value|" "$USER_SETTINGS_FILE"
        echo "[INFO | metrics] Updated $key in $USER_SETTINGS_FILE"
    else
        # Add the new key
        echo "$key=$value" >>"$USER_SETTINGS_FILE"
        echo "[INFO | metrics] Added $key to $USER_SETTINGS_FILE"
    fi
}

source_assets_envs() {
    set -a # Export all variables

    # shellcheck disable=SC1091
    if [ -f "${ASSETS_DIR}/variables.env" ]; then
        . "${ASSETS_DIR}/variables.env"

    else
        echo "[ERROR | configure] Missing variables file (${ASSETS_DIR}/variables.env)"
        exit 1
    fi

    if [ -z "${_ASSETS_VERSION:-}" ]; then
        _ASSETS_VERSION="$(cat /assets/version)"
    fi

    set +a
}

source_user_settings() {
    # Ensure user settings file exists
    if [ -f "$USER_SETTINGS_FILE" ]; then
        set -a
        # shellcheck disable=SC1090
        . "$USER_SETTINGS_FILE"
        set +a
    fi
}

update_user_settings

if [ "${SHUTTER_PUSH_METRICS_ENABLED}" = "false" ]; then
    echo "[INFO | metrics] Metrics push is disabled"
    exit 0
fi

source_assets_envs

source_user_settings

exec /vmagent-prod \
    -promscrape.config="${CONFIG_FILE}" \
    -remoteWrite.url="${PUSHGATEWAY_URL}" \
    -remoteWrite.basicAuth.username="${PUSHGATEWAY_USERNAME}" \
    -remoteWrite.basicAuth.password="${PUSHGATEWAY_PASSWORD}"
