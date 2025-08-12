# Backup and Restore Guide

This guide explains how to backup and restore your Shutter API DAppNode package data.

## Backup Creation

DAppNode provides a built-in backup functionality through the DAppNode UI. Users can create backup archives directly from the interface, which generates a compressed tar file that should be downloaded for safekeeping.

### What Gets Backed Up

The package automatically backs up the following critical data:

- **Keyper Configuration** (`/keyper/config`): Contains your Shutter Keyper settings and configuration files
- **Chain Configuration** (`/chain/config`): Contains your Shutter Chain node configuration
- **Database Data** (`/var/lib/postgresql/data`): Contains the PostgreSQL database with your Keyper's state
- **Metrics Configuration** (`/config/user`): Contains your metrics service configuration

### Creating a Backup

1. Navigate to your DAppNode UI
2. Go to the Shutter API package
3. Click on the "Backup" option
4. Wait for the backup process to complete
5. Download the generated backup file to a secure location

## Restore Process

The restore process requires a two-step approach:

### Step 1: Package Installation
The DAppNode package must be installed first through the DAppNode UI. This creates a fresh installation with default configuration.

### Step 2: Backup Restoration
Once installation is complete, the previously downloaded backup file can be restored to the newly installed package. This will restore all your previous data.

## Environment Variables

After restoration, the environment variables in the restored deployment will match those configured during the package installation of restore process. This includes:

- `KEYPER_NAME`: Your unique keyper identifier
- `SHUTTER_API_NODE_PRIVATEKEY`: Your Ethereum private key
- `ETHEREUM_WS`: Your Ethereum WebSocket RPC endpoint
- `SHUTTER_PUSH_METRICS_ENABLED`: Metrics push configuration
- `PUSHGATEWAY_URL`: Metrics push gateway URL
- `PUSHGATEWAY_USERNAME`: Push gateway authentication
- `PUSHGATEWAY_PASSWORD`: Push gateway authentication

## Security Considerations

⚠️ **Important Security Notes:**

- The backup archive contains previous configuration files that will include sensitive data
- Your private keys and configuration are stored in the backup
- Store backup files in a secure, encrypted location
- Never share backup files with untrusted parties

## Troubleshooting

If you encounter issues during backup or restore:

1. Ensure you have sufficient disk space for backup creation
2. Verify that all services are running before creating a backup
3. Check that the backup file was downloaded completely
4. Ensure the package is fully installed before attempting restore
5. Contact DAppNode support if restore fails
