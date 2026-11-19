#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
bash scripts/abi-extractor/extract.sh
if ! find packages/contract-abis/abi -maxdepth 1 -name '*.json' -print -quit | grep -q .; then
  echo 'ERROR: No ABIs extracted; refusing to generate empty bindings' >&2
  exit 1
fi
node scripts/abi-extractor/generate-types.js
npm run build -w @stellarlend/contract-abis
