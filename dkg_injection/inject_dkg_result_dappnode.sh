#!/usr/bin/env bash

# This script overrides a selected DKG result in the live keyper database
# with the corresponding data from a Dappnode backup. The following tables are
# affected:
# - dkg_result (columns: success, error, pure_result)
# - keyper_set (columns: keypers, threshold)
# - tendermint_batch_config (columns: keypers, threshold)
#
# Usage:
#   ./inject_dkg_result_dappnode.sh <path-to-backup.tar>
#
# Ensure the node is sufficiently synced before running. If the keyper
# service is running, it will be stopped during the operation and
# restarted afterwards. The database service will be started if not
# already running, and stopped again afterwards if it was not running.

set -euo pipefail

EON="11"
KEYPER_CONFIG_INDEX="11"
MIN_TENDERMINT_CURRENT_BLOCK="0"

BACKUP_CONTAINER="backup-db"
BACKUP_IMAGE="postgres:16"
BACKUP_DB="postgres"
BACKUP_USER="postgres"
BACKUP_PASSWORD="postgres"
KEYPER_DB="keyper"
BACKUP_TABLE_SUFFIX="_backup"

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t inject-dkg-result)"
TABLES=(
  "dkg_result:eon:${EON}:success, error, pure_result"
  "tendermint_batch_config:keyper_config_index:${KEYPER_CONFIG_INDEX}:keypers, threshold"
  "keyper_set:keyper_config_index:${KEYPER_CONFIG_INDEX}:keypers, threshold"
)

log() {
  echo "==> $1"
}

usage() {
  echo "Usage: $(basename "$0") <path-to-backup.tar|path-to-backup.tar.xz>" >&2
  exit 1
}

if [[ "$#" -ne 1 ]]; then
  usage
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "ERROR: required command 'tar' not found in PATH" >&2
  exit 1
fi

BACKUP_TARBALL_PATH="$1"

if [[ ! -f "$BACKUP_TARBALL_PATH" ]]; then
  echo "ERROR: tarball not found: $BACKUP_TARBALL_PATH" >&2
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${BACKUP_CONTAINER}\$"; then
  echo "ERROR: container '${BACKUP_CONTAINER}' already exists. Aborting." >&2
  exit 1
fi

DB_WAS_RUNNING=0
KEYPER_WAS_RUNNING=0

LIVE_DB_CONTAINER="${LIVE_DB_CONTAINER:-DAppNodePackage-db.shutter-api-gnosis.dnp.dappnode.eth}"
if docker ps --format '{{.Names}}' | grep -q "^${LIVE_DB_CONTAINER}\$"; then
  DB_WAS_RUNNING=1
fi

LIVE_KEYPER_CONTAINER="${LIVE_KEYPER_CONTAINER:-DAppNodePackage-shutter.shutter-api-gnosis.dnp.dappnode.eth}"
if docker ps --format '{{.Names}}' | grep -q "^${LIVE_KEYPER_CONTAINER}\$"; then
  KEYPER_WAS_RUNNING=1
fi

cleanup() {
  rv=$?
  if [[ "$rv" -ne 0 ]]; then
    echo "Aborting due to error (exit code $rv)" >&2
  fi

  log "Stopping backup container"
  docker stop "$BACKUP_CONTAINER" >/dev/null 2>&1 || true

  if [[ "$KEYPER_WAS_RUNNING" -eq 1 ]]; then
    log "Restarting keyper service (was running before)"
    docker start "$LIVE_KEYPER_CONTAINER" >/dev/null 2>&1 || true
  else
    log "Leaving keyper service stopped (was not running before)"
  fi

  if [[ "$DB_WAS_RUNNING" -eq 0 ]]; then
    log "Stopping db service (was not running before)"
    docker stop "$LIVE_DB_CONTAINER" >/dev/null 2>&1 || true
  else
    log "Keeping db service running (was running before)"
  fi

  if [[ -d "$TMP_DIR" ]]; then
    log "Removing temporary directory ${TMP_DIR}"
    rm -rf "$TMP_DIR"
  fi

  exit "$rv"
}
trap cleanup EXIT

if [[ "$DB_WAS_RUNNING" -eq 0 ]]; then
  log "Starting db service (was not running)"
  docker start "$LIVE_DB_CONTAINER" >/dev/null
fi

log "Checking shuttermint sync block number >= ${MIN_TENDERMINT_CURRENT_BLOCK}"
CURRENT_BLOCK=$(docker exec -i "$LIVE_DB_CONTAINER" sh -lc \
  "psql -t -A -U postgres -d ${KEYPER_DB} -c \"SELECT current_block FROM tendermint_sync_meta ORDER BY current_block DESC LIMIT 1\"" \
  2>/dev/null | tr -d '[:space:]')

if [[ -z "$CURRENT_BLOCK" ]]; then
  echo "ERROR: failed to read shuttermint sync block number" >&2
  exit 1
fi

if ! [[ "$CURRENT_BLOCK" =~ ^[0-9]+$ ]]; then
  echo "ERROR: shuttermint sync block number is not an integer: $CURRENT_BLOCK" >&2
  exit 1
fi

if (( CURRENT_BLOCK < MIN_TENDERMINT_CURRENT_BLOCK )); then
  echo "ERROR: shuttermint sync block number ($CURRENT_BLOCK) is below MIN_TENDERMINT_CURRENT_BLOCK ($MIN_TENDERMINT_CURRENT_BLOCK); aborting. Please wait until the node is sufficiently synced and try again." >&2
  exit 1
fi

log "Stopping keyper service"
docker stop "$LIVE_KEYPER_CONTAINER" >/dev/null 2>&1 || true

log "Extracting keyper DB from backup"
TAR_WARNING_FLAGS=()
if tar --help 2>/dev/null | grep -q -- '--warning'; then
  TAR_WARNING_FLAGS+=(--warning=no-unknown-keyword)
fi

EXTRACT_DIR="${TMP_DIR}/backup-extract"
TAR_ERROR_FILE="${TMP_DIR}/tar-extract.err"
extract_backup() {
  rm -rf "$EXTRACT_DIR"
  mkdir -p "$EXTRACT_DIR"
  tar "${TAR_WARNING_FLAGS[@]}" "$1" "$BACKUP_TARBALL_PATH" -C "$EXTRACT_DIR" 2>"$TAR_ERROR_FILE"
}

if ! extract_backup -xf; then
  if ! extract_backup -xJf; then
    echo "ERROR: failed to extract backup tarball: $BACKUP_TARBALL_PATH" >&2
    if [[ -s "$TAR_ERROR_FILE" ]]; then
      cat "$TAR_ERROR_FILE" >&2
    fi
    exit 1
  fi
fi

if [[ -z "$(find "$EXTRACT_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
  echo "ERROR: backup tarball extracted no files: $BACKUP_TARBALL_PATH" >&2
  exit 1
fi

DB_DATA_DIR=""
while IFS= read -r -d '' d; do
  if [[ -d "$d" && -f "$d/PG_VERSION" ]]; then
    DB_DATA_DIR="$d"
    break
  fi
done < <(find "$EXTRACT_DIR" -type d -name "db-data" -print0 2>/dev/null)

if [[ -z "$DB_DATA_DIR" || ! -d "$DB_DATA_DIR" ]]; then
  echo "ERROR: could not find db-data directory (Postgres data) inside backup" >&2
  exit 1
fi

log "Starting backup container"
docker run -d --rm \
  --name "$BACKUP_CONTAINER" \
  -e POSTGRES_USER="$BACKUP_USER" \
  -e POSTGRES_PASSWORD="$BACKUP_PASSWORD" \
  -e POSTGRES_DB="$BACKUP_DB" \
  -v "$DB_DATA_DIR:/var/lib/postgresql/data" \
  "$BACKUP_IMAGE" >/dev/null

log "Waiting for backup DB to become ready"
for i in {1..30}; do
  if docker exec "$BACKUP_CONTAINER" pg_isready -U "$BACKUP_USER" -d "$BACKUP_DB" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
if ! docker exec "$BACKUP_CONTAINER" pg_isready -U "$BACKUP_USER" -d "$BACKUP_DB" >/dev/null 2>&1; then
  echo "ERROR: backup DB did not become ready after 30 seconds" >&2
  exit 1
fi

for entry in "${TABLES[@]}"; do
  IFS=: read -r TABLE KEY_COLUMN KEY_VALUE SELECT_COLUMNS <<<"$entry"
  BACKUP_CSV_FILE="${TMP_DIR}/${TABLE}_backup_${KEY_COLUMN}_${KEY_VALUE}.csv"
  LIVE_CSV_FILE="${TMP_DIR}/${TABLE}_live_${KEY_COLUMN}_${KEY_VALUE}.csv"
  SELECT_COLUMN_LIST=()

  for col in ${SELECT_COLUMNS//,/ }; do
    [[ -z "$col" ]] && continue
    if [[ "$col" == "$KEY_COLUMN" ]]; then
      echo "ERROR: column list for ${TABLE} must not include key column ${KEY_COLUMN}" >&2
      exit 1
    fi
    SELECT_COLUMN_LIST+=("$col")
  done

  if [[ "${#SELECT_COLUMN_LIST[@]}" -eq 0 ]]; then
    echo "ERROR: no non-key columns specified for update in ${TABLE}" >&2
    exit 1
  fi

  SELECT_COLUMN_LIST_WITH_KEY=("$KEY_COLUMN" "${SELECT_COLUMN_LIST[@]}")
  SELECT_COLUMNS_WITH_KEY=$(IFS=', '; echo "${SELECT_COLUMN_LIST_WITH_KEY[*]}")

  log "Extracting ${TABLE} row ${KEY_COLUMN}=${KEY_VALUE} from backup DB"
  docker exec "$BACKUP_CONTAINER" bash -lc \
    "psql -v ON_ERROR_STOP=1 -U '$BACKUP_USER' -d '$KEYPER_DB' -c \"COPY (SELECT ${SELECT_COLUMNS_WITH_KEY} FROM ${TABLE} WHERE ${KEY_COLUMN} = '${KEY_VALUE}' LIMIT 1) TO STDOUT WITH CSV\"" \
    >"$BACKUP_CSV_FILE" 2>/dev/null

  if [[ ! -s "$BACKUP_CSV_FILE" ]]; then
    echo "ERROR: no data extracted from backup DB (no row with ${KEY_COLUMN}=${KEY_VALUE} in ${TABLE})" >&2
    exit 1
  fi

  log "Extracting ${TABLE} row ${KEY_COLUMN}=${KEY_VALUE} from live DB"
  docker exec -i "$LIVE_DB_CONTAINER" sh -lc \
    "psql -v ON_ERROR_STOP=1 -U postgres -d ${KEYPER_DB} -c \"COPY (SELECT ${SELECT_COLUMNS_WITH_KEY} FROM ${TABLE} WHERE ${KEY_COLUMN} = '${KEY_VALUE}' LIMIT 1) TO STDOUT WITH CSV\"" \
    >"$LIVE_CSV_FILE" 2>/dev/null || true

  if [[ ! -s "$LIVE_CSV_FILE" ]]; then
    echo "ERROR: no data extracted from live DB (no row with ${KEY_COLUMN}=${KEY_VALUE} in ${TABLE})" >&2
    exit 1
  fi

  if [[ -s "$LIVE_CSV_FILE" && -s "$BACKUP_CSV_FILE" && "$(cat "$LIVE_CSV_FILE")" == "$(cat "$BACKUP_CSV_FILE")" ]]; then
    log "Live row for ${TABLE} already matches backup, nothing to do"
    continue
  fi

  BACKUP_TABLE_NAME="${TABLE}${BACKUP_TABLE_SUFFIX}"

  log "Backing up table ${TABLE} to ${BACKUP_TABLE_NAME} in live DB"
  {
    echo "CREATE TABLE IF NOT EXISTS ${BACKUP_TABLE_NAME} (LIKE ${TABLE} INCLUDING ALL);"
    echo "TRUNCATE ${BACKUP_TABLE_NAME};"
    echo "INSERT INTO ${BACKUP_TABLE_NAME} SELECT * FROM ${TABLE};"
  } | docker exec -i "$LIVE_DB_CONTAINER" psql -U postgres -d "${KEYPER_DB}" >/dev/null 2>&1

  UPDATE_SET=""
  for col in "${SELECT_COLUMN_LIST[@]}"; do
    if [[ -z "$UPDATE_SET" ]]; then
      UPDATE_SET="${col} = u.${col}"
    else
      UPDATE_SET="${UPDATE_SET}, ${col} = u.${col}"
    fi
  done

  log "Restoring ${TABLE} row ${KEY_COLUMN}=${KEY_VALUE}"
  {
    echo "BEGIN;"
    echo "CREATE TEMP TABLE tmp_update AS SELECT ${SELECT_COLUMNS_WITH_KEY} FROM ${TABLE} WHERE 1=0;"
    echo "COPY tmp_update FROM STDIN WITH CSV;"
    cat "$BACKUP_CSV_FILE"
    echo '\.'
    echo "UPDATE ${TABLE} AS t SET ${UPDATE_SET} FROM tmp_update u WHERE t.${KEY_COLUMN} = u.${KEY_COLUMN};"
    echo "COMMIT;"
  } | docker exec -i "$LIVE_DB_CONTAINER" psql -U postgres -d "${KEYPER_DB}" >/dev/null 2>&1
done

log "Done"
