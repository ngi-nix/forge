#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

: "${PACKAGES:=--all}"
: "${TARGET_BRANCH:=master}"

export PACKAGES TARGET_BRANCH DRY_RUN=true

echo ""
echo "==> Dry-run with:"
echo "    PACKAGES      : $PACKAGES"
echo "    TARGET_BRANCH : $TARGET_BRANCH"
echo ""

echo "==> Update packages"
"$SCRIPT_DIR/update-packages.sh"
echo ""

echo "==> Create list of valid packages"
nix eval '.#packages.x86_64-linux' --apply 'builtins.attrNames' --json \
  >/tmp/valid-packages.json
echo ""

echo "==> Create one PR per updated package"
"$SCRIPT_DIR/create-prs.sh"
echo ""

echo "==> Done"
