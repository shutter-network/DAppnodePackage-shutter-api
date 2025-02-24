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

   - `KEYPER_NAME`
   - `SHUTTER_API_NODE_PRIVATEKEY`
   - `ETHEREUM_WS`
   - `SHUTTER_PUSH_METRICS_ENABLED`
   - `PUSHGATEWAY_URL`
   - `PUSHGATEWAY_USERNAME`
   - `PUSHGATEWAY_PASSWORD`
