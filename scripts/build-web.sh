#!/usr/bin/env bash
# Build the web deployment directory.
#
# Usage:
#   scripts/build-web.sh
#
# What it does:
#   1. Copies the web player shell from web/ into dist/web/.
#   2. Copies game assets from game/ into dist/web/, excluding Windows-only and
#      developer-only files.
#   3. Preserves the player files and host config while cleaning out stale game
#      assets in the build output.
#   4. Runs generate_index.py to regenerate dist/web/index.json.
#
# The EasyRPG Player files must already be present in web/ before running this
# script. Download them from the EasyRPG web build archive.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME_DIR="$REPO_ROOT/game"
WEB_DIR="$REPO_ROOT/web"
DIST_DIR="$REPO_ROOT/dist/web"
PLAYER_REQUIRED=(
  "index.html"
  "index.js"
  "index.wasm"
)

# Files to exclude from the web build (Windows-only, editor-only, dev artifacts)
EXCLUDES=(
  "RPG_RT.exe"
  "RPG_RT.exe.mbxcfg"
  "RPG_RT.exe.old"
  "ultimate_rt_eb.dll"
  "logo.rc"
  "The_Funny_Guy_RPG.r3proj"
  "audio-removal-log.md"
)

# Build rsync exclude flags
RSYNC_EXCLUDES=()
for f in "${EXCLUDES[@]}"; do
  RSYNC_EXCLUDES+=(--exclude="$f")
done
# Also exclude save files and hidden files
RSYNC_EXCLUDES+=(--exclude="Save*.lsd" --exclude=".*")

for f in "${PLAYER_REQUIRED[@]}"; do
  if [[ ! -f "$WEB_DIR/$f" ]]; then
    echo "error: missing required EasyRPG web player file: web/$f" >&2
    echo "download the EasyRPG web build into web/ before running this script" >&2
    exit 1
  fi
done

mkdir -p "$DIST_DIR"

echo "==> Syncing web shell: web/ -> dist/web/"
rsync -av --delete \
  --exclude=".*" \
  "$WEB_DIR/" "$DIST_DIR/"

echo ""
echo "==> Syncing game assets: game/ -> dist/web/"
rsync -av --delete \
  "--filter=P /index.html" \
  "--filter=P /index.js" \
  "--filter=P /index.wasm" \
  "--filter=P /favicon.png" \
  "--filter=P /_headers" \
  "--filter=P /netlify.toml" \
  "--filter=P /index.json" \
  "${RSYNC_EXCLUDES[@]}" \
  "$GAME_DIR/" "$DIST_DIR/"

echo ""
echo "==> Generating file index"
python3 "$REPO_ROOT/scripts/generate_index.py" "$DIST_DIR"

echo ""
echo "Done. Serve with: python3 -m http.server 8080 --directory dist/web/"
