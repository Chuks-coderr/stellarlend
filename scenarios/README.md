# Local scenario replay

The devnet snapshot helper is `scripts/devnet/snapshot.sh`. Snapshots include
`.devnet/state.json` **and** the Docker container's mounted ledger volumes;
metadata alone is insufficient to replay a scenario.

```bash
npm run devnet
bash scripts/devnet/snapshot.sh save before-liquidation
# run your scenario against the local network
bash scripts/devnet/snapshot.sh restore before-liquidation --force
bash scripts/devnet/snapshot.sh list
```

**Safety:** restore destroys the current mounted ledger state. The tool refuses
to restore without `--force`, rejects invalid names, and requires the same
mount layout. It stops the devnet container while copying data. The snapshot
helper requires a persistent-volume-backed local container; ephemeral
containers without mounts are rejected. Never use it against a shared network.
The helper uses the `alpine:3.20` image for volume archive operations.
