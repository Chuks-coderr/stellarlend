#!/usr/bin/env bash
# Save and restore a complete Docker-backed local devnet, including ledger data.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${DEVNET_STATE_DIR:-$ROOT/.devnet}"
CONTAINER="${DEVNET_CONTAINER:-stellar-local}"
usage() { echo "Usage: $0 save|restore|list <scenario-name> [--force]" >&2; exit 2; }
[[ $# -ge 1 ]] || usage
ACTION="$1"; shift
[[ "$ACTION" == save || "$ACTION" == restore || "$ACTION" == list ]] || usage
NAME="${1:-}"
[[ "$ACTION" == list ]] || [[ "$NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$ ]] || usage
[[ "$ACTION" == list ]] || shift
FORCE=false
if [[ "${1:-}" == --force ]]; then FORCE=true; shift; fi
[[ $# == 0 ]] || usage
DEST="$STATE_DIR/snapshots/$NAME"
if [[ "$ACTION" == list ]]; then
  if [[ -d "$STATE_DIR/snapshots" ]]; then find "$STATE_DIR/snapshots" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort; fi
  exit 0
fi
command -v docker >/dev/null || { echo "ERROR: docker required" >&2; exit 1; }
command -v tar >/dev/null || { echo "ERROR: tar required" >&2; exit 1; }
[[ -f "$STATE_DIR/state.json" ]] || { echo "ERROR: devnet not bootstrapped" >&2; exit 1; }
[[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" == true ]] || { echo "ERROR: container $CONTAINER is not running" >&2; exit 1; }
# Identify all named/anonymous mounts and fail closed rather than silently saving metadata only.
MOUNTS="$(docker inspect --format '{{range .Mounts}}{{println .Destination}}{{end}}' "$CONTAINER")"
if [[ -z "$MOUNTS" ]]; then
  echo "ERROR: container has no persistent ledger mounts; cannot guarantee replay" >&2; exit 1
fi
if [[ "$ACTION" == save ]]; then
  [[ ! -e "$DEST" ]] || { echo "ERROR: snapshot exists: $NAME" >&2; exit 1; }
  mkdir -p "$STATE_DIR/snapshots"
  TMP="$(mktemp -d "$STATE_DIR/snapshots/.pending.XXXXXXXX")"
  trap 'rm -rf "$TMP"' EXIT
  cp "$STATE_DIR/state.json" "$TMP/state.json"
  printf '%s\n' "$MOUNTS" > "$TMP/mounts.txt"
  # Stop all writes before copying the mounted ledger state.
  docker stop "$CONTAINER" >/dev/null
  trap 'docker start "$CONTAINER" >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT
  i=0
  while IFS= read -r mount; do
    [[ -n "$mount" ]] || continue
    docker run --rm --volumes-from "$CONTAINER":ro -v "$TMP:/snapshot" alpine:3.20 sh -c 'cd "$1" && tar -cf "/snapshot/mount-'"$i"'.tar" .' sh "$mount"
    i=$((i+1))
  done <<< "$MOUNTS"
  docker start "$CONTAINER" >/dev/null
  mv "$TMP" "$DEST"
  trap - EXIT
  echo "Saved devnet snapshot: $NAME ($i mounts)"
else
  [[ -f "$DEST/state.json" && -f "$DEST/mounts.txt" ]] || { echo "ERROR: snapshot not found: $NAME" >&2; exit 1; }
  [[ "$FORCE" == true ]] || { echo "ERROR: restore overwrites live ledger; pass --force" >&2; exit 2; }
  cmp -s "$DEST/mounts.txt" <(printf '%s\n' "$MOUNTS") || { echo "ERROR: container mounts differ from snapshot" >&2; exit 1; }
  docker stop "$CONTAINER" >/dev/null
  trap 'docker start "$CONTAINER" >/dev/null 2>&1 || true' EXIT
  i=0
  while IFS= read -r mount; do
    [[ -n "$mount" ]] || continue
    [[ -f "$DEST/mount-$i.tar" ]] || { echo "ERROR: missing mount archive $i" >&2; exit 1; }
    docker run --rm --volumes-from "$CONTAINER" -v "$DEST:/snapshot:ro" alpine:3.20 sh -c 'cd "$1" && find . -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + && tar -xf "/snapshot/mount-'"$i"'.tar"' sh "$mount"
    i=$((i+1))
  done < "$DEST/mounts.txt"
  cp "$DEST/state.json" "$STATE_DIR/state.json"
  docker start "$CONTAINER" >/dev/null
  trap - EXIT
  echo "Restored devnet snapshot: $NAME ($i mounts)"
fi
