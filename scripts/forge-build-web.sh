#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${FORGE_RELEASE_DIRECTORY:-}" ]]; then
  REPO_ROOT="$FORGE_RELEASE_DIRECTORY"
elif [[ -n "${FORGE_SITE_PATH:-}" ]]; then
  REPO_ROOT="$FORGE_SITE_PATH"
else
  REPO_ROOT="$(pwd)"
fi

cd "$REPO_ROOT"

scripts/build-web.sh
