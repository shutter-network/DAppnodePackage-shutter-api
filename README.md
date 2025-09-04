# Shutter API Dappnode Package

This package runs a **Shutter API Keyper**, as well as its corresponding **Shutter Chain** node, along with a **metrics service** to monitor the node's performance and a **PostgreSQL database** to store the Keyper's state.

### Services

This package includes the following services:

- **Shutter API Keyper (`shutter`)**:

  - There is a supervisor daemon that first ensures all the initialization and configuration processes are completed and then it starts the `chain` process. Once the `chain` process is healthy, the `keyper` is started, too. To do all this, the supervisor runs the scripts contained in `/usr/local/bin`, following this order: `configure.sh` → `run_chain.sh` → `run_keyper.sh`.

  - Configuration files for Shutter are generated and managed in `/keyper/config` and `/chain/config`.

- **PostgreSQL Database (`db`)**:

  - The database stores the state of the Shutter Keyper and is initialized using the `entrypoint.sh` script.

  - Data is persisted in the `db_data` volume, which maps to `/var/lib/postgresql/data`.

- **Metrics Service (`metrics`)**:

  - Uses VictoriaMetrics to send performance metrics to a remote Pushgateway.

  - Configuration is handled via the config file `/config/gnosis/vmagent.yml`, placehoders in that file are automatically picked up from the environment by vmagent.

### Configuration

The setup wizard provides options for users to configure the package. These values need to be filled:

   - `KEYPER_NAME`: a unique name for your keyper so it can be identified in the network.
   - `SHUTTER_API_NODE_PRIVATEKEY`: A privatekey for an ethereum externally owned account.
   - `ETHEREUM_WS`: An optional ethereum websocket RPC url. This can either point to an external RPC, or an RPC node running on your dappnode. If it is not given, shutter will try to use an internal RPC through the 'staker scripts' mechanism.
   - `SHUTTER_PUSH_METRICS_ENABLED`: A boolean flag deciding whether metrics will be pushed (see values below).
   - `PUSHGATEWAY_URL`: You don't need to change the default here.
   - `PUSHGATEWAY_USERNAME`: A username for the push gateway from above.
   - `PUSHGATEWAY_PASSWORD`: A password for the push gateway from above.
   - `SHUTTER_PUSH_LOGS_ENABLED`: A boolean flag to enable log collection. This feature enables log pushing to a Loki/VmLogs server, allowing the Shutter team to collect and monitor keyper logs for troubleshooting and network monitoring purposes.
   - `SHUTTER_HTTP_ENABLED`: A boolean flag to enable HTTP service endpoints. This should remain **false** unless specifically requested by the Shutter team. When enabled, this will expose additional keyper HTTP endpoints for advanced monitoring and debugging.


### Backup and Restore

For information on backing up and restoring your Shutter API package data, see the [Backup and Restore Guide](https://github.com/shutter-network/DAppnodePackage-shutter-api/blob/main/backup_and_restore.md).

### Developer notes

Building the package requires docker and a vpn connection to a dappnode. It can be run with:

```
npx @dappnode/dappnodesdk@latest build --all-variants
```
