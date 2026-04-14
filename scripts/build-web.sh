#!/usr/bin/env bash
# Build the web deployment directory.
#
# Usage:
#   scripts/build-web.sh
#
# What it does:
#   1. Copies game assets from game/ into web/, excluding Windows-only and
#      developer-only files.
#   2. Runs generate_index.py to regenerate web/index.json.
#
# The EasyRPG Player files (index.html, easyrpg-player.js, easyrpg-player.wasm)
# must already be present in web/ before running this script. Download them from
# https://github.com/EasyRPG/Player/releases (web build archive).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME_DIR="$REPO_ROOT/game"
WEB_DIR="$REPO_ROOT/web"

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

echo "==> Syncing game assets: game/ -> web/"
rsync -av --delete \
  "${RSYNC_EXCLUDES[@]}" \
  "$GAME_DIR/" "$WEB_DIR/"

echo ""
echo "==> Generating file index"
python3 "$REPO_ROOT/scripts/generate_index.py" "$WEB_DIR"

echo ""
echo "Done. Serve with: python3 -m http.server 8080 --directory web/"
