# Wave 11 developer workflows

## Snapshot replay (#1706)
Use `bash scripts/devnet/snapshot.sh save <name>` to capture the local
volume-backed ledger and bootstrap state. Use `list` to see snapshots and
`restore <name> --force` to reset the local ledger. See
[scenario replay](../scenarios/README.md). The container must have persistent
mounts; restoring overwrites current state.

## WASM diff (#1696)
The `Soroban WASM binary diff` PR workflow builds both base and head
and publishes a per-artifact size/hash comparison in the Actions job summary.
A changed hash is informational, not proof of a semantic or security regression.

## TypeScript bindings (#1700)
Run `bash scripts/abi-extractor/build-bindings.sh` after changing contracts.
The command extracts ABIs, generates TypeScript definitions and builds
`@stellarlend/contract-abis`. Extraction must produce at least one ABI.

## VS Code tasks (#1708)
Open the repository root in VS Code, then run **Tasks: Run Task**.
Available tasks: contract build, contract tests, local devnet bootstrap,
local deployment/bootstrap, and TypeScript binding regeneration.
Requires Rust, Stellar CLI, Docker and Node dependencies as appropriate.
