#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# TODO: add `external-sources=true` in .shellcheckrc?
# (see https://www.shellcheck.net/wiki/SC1091)
#
# shellcheck disable=SC1091
source "$SCRIPT_DIR/debug.sh"

: "${PACKAGES:=--all}"
: "${TARGET_BRANCH:=master}"

UPDATE_ARGS="--commit"

if [[ ${DRY_RUN:-false} == "true" ]]; then
  UPDATE_ARGS="--dry-run"
fi

debug_run git checkout "$TARGET_BRANCH"
nix develop --command forge-update "$PACKAGES" "$UPDATE_ARGS" 2>&1 | tee /tmp/update-all.log

# Save commit-list of updated packages
git log --reverse origin/"$TARGET_BRANCH"..HEAD --format="%H %s" |
  grep "recipes(" >/tmp/commits.txt || true
