# Dappnode Keypers: How to use DKG injection script

This guide describes the process for how **Dappnode** keypers can use the DKG injection script in the **shutter-api-1002** deployment.

## Purpose

To restore key material generated during previous deployment, necessary to fulfill pending decryption tasks.

---

**Initial Keypers**: Keypers who were active during **eon 11**. Timestamp range: Mar-24-2025 01:03:45 PM UTC (1742821425) - Dec-01-2025 11:25:35 AM UTC (1764588335).

---

## Prerequisites

- Fully synced keyper running the shutter-api-1002 deployment version on Dappnode
- The same signing keys used for initial keyper deployment
- Dappnode backup from the initial keyper
- Access to Dappnode instance via shell

---

## Process Steps

### 1. Run Keypers with Same Signing Keys

In the **shutter-api-1002** deployment, run the keypers with the **same signing keys** that were used previously for the initial keypers deployment and wait for them to sync with the network.

Sync can be confirmed by this log line:

```
synced registry contract end-block=20044460 num-discarded-events=0 num-inserted-events=0 start-block=20044460
```

The **end-block** should be (or greater than) the current head of the chain in the explorer.

### 2. Ensure the backup is copied to the same instance

Copy the backup to the same instance where the keyper is running.

### 3. Run DKG Injection Script (Dappnode)

After a keyperset transition is done, run the Dappnode DKG injection script with the backup path:

```bash
curl -fsSL https://raw.githubusercontent.com/shutter-network/DAppnodePackage-shutter-api/dkg-injection/dkg_injection/inject_dkg_result_dappnode.sh | bash -s -- <path_to_dappnode_backup>
```

Replace `<path_to_dappnode_backup>` with the actual path to your Dappnode backup archive.

Check if there is no error in running the script. The output should look something like this:

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
==> Done
==> Stopping backup container
==> Restarting keyper service (was running before)
==> Keeping db service running (was running before)
==> Removing temporary directory /tmp/tmp.7l26Tilq40
```

---

## Summary Checklist

| Step | Action |
|------|--------|
| 1 | Run keypers in shutter-api-1002 with same signing keys as initial keypers and wait for keypers to sync |
| 2 | Ensure the Dappnode backup archive is copied to the same instance |
| 3 | Run the Dappnode DKG injection script with the backup archive path |

