# How to use the DKG injection script to restore the time capsule key shares into an existing DAppNode instance

This guide describes the process to inject the Ethereum Time Capsule Key shares generated under the initial deployment of the Shutter API Keyper set and backed up under [the initial DAppNode deployment](https://github.com/shutter-network/DAppnodePackage-shutter-api/releases/tag/chiado%400.1.0_gnosis%400.1.5) ([DAppNode Explorer link](https://dappnode.github.io/explorer/#/repo/0x8928c414c10d5eeaf2eea30702b3a0c03d52ff6f/0.1.5))

This is needed to generate the time capsule decryption keys when the decryption timestamp is reached.

Initial Keypers refer to the Keypers who were active during eon 11 of the initial API Keyper deployment. Timestamp range: Mar-24-2025 01:03:45 PM UTC (1742821425) - Dec-01-2025 11:25:35 AM UTC (1764588335).

## Prerequisites

- Fully synced Keyper running the latest Shutter API 1002 DAppNode deployment version. [Release](https://github.com/shutter-network/DAppnodePackage-shutter-api/compare/chiado@v0.1.0_gnosis@v0.1.9...chiado@v0.1.0_gnosis@v0.1.10) | [DAppNode Explorer link](https://dappnode.github.io/explorer/#/repo/0x8928c414c10d5eeaf2eea30702b3a0c03d52ff6f/0.1.10)
- The same Ethereum signing key used during the time capsule key collection.
- DAppNode backup of the initial Keyper keys requested in November 2025.
- Access to the DAppNode instance via shell.

## Process Steps

### 1. Start a Keyper instance with the correct Ethereum key

All Keypers have already been requested to start a new instance with the Ethereum signing key they used during the time capsule key generation.

This step has already been performed, and all Keypers are running the latest Shutter API 1002 DAppNode deployment with the Ethereum signing key used during the time capsule collection.

### 2. Check that your Keyper Gnosis chain is sufficiently synced

The syncing status can be confirmed if you see the below logs:

```
synced registry contract end-block=46640633 num-discarded-events=0 num-inserted-events=0 start-block=46640633
```

The **end-block** should be greater than block 44980000, which corresponds to Mar 4, 2026.

Note: Some Keypers have been running into rate-limiting issues and are not able to sync fully. This is currently not an issue as long as they are synced past the required activation block number, which they already are.

## 3. SSH into DAppNode

SSH into the DAppNode machine as described in the DAppNode docs:

`ssh dappnode@<DAPPNODE_LOCAL_IP_ADDRESS>`

from the same network. Use the password set during onboarding.

Source:
https://docs.dappnode.io/docs/user/access-your-dappnode/terminal/

### 4. Ensure the backup is copied to your DAppNode machine

Copy the November Time Capsule DAppNode backup to your DAppNode machine, under a designated folder `<path_to_dappnode_backup>.`

### 5. Run the DAppNode DKG injection script

Run the DAppNode DKG injection script and provide the correct time capsule backup path:

```shell
curl -fsSL https://raw.githubusercontent.com/shutter-network/DAppnodePackage-shutter-api/dkg-injection/dkg_injection/inject_dkg_result_dappnode.sh | bash -s -- <path_to_dappnode_backup>
```

Replace `<path_to_dappnode_backup>` with the actual path to your DAppNode time capsule backup archive.

Check that there is no error when running the script. The output should look something like this:

```
==> Checking shuttermint sync block number >= 349800
==> Stopping keyper service
==> Extracting keyper DB from backup
==> Starting backup container
==> Waiting for backup DB to become ready
==> Checking backup DB state
==> Checking if backup tables already exist
==> Backing up tables
==> Injecting DKG result
==> Verifying injected data
==> Done
==> Stopping backup container
==> Restarting keyper service (was running before)
==> Keeping db service running (was running before)
==> Removing temporary directory /tmp/tmp.7l26Tilq40
```

### 6. Report the result of the script

Please report the result of the script to the Shutter team under your individual Keyper group.
