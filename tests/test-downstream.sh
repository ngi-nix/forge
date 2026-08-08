#!/usr/bin/env bash
set -e

REPO_ROOT="$PWD"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cp -r tests/fixtures/* "$TMP_DIR/"
sed -i "s|PATH_TO_FORGE|path:$REPO_ROOT|g" "$TMP_DIR"/downstream-flake-fail/flake.nix
sed -i "s|PATH_TO_FORGE|path:$REPO_ROOT|g" "$TMP_DIR"/downstream-flake-pass/flake.nix

echo "Testing flake without allowlist"
if nix eval --no-write-lock-file "path:$TMP_DIR/downstream-flake-fail#packages.x86_64-linux.dummy.drvPath" 2>/dev/null; then
  echo "Failed: leaked"
  exit 1
fi

echo "Testing flake with allowlist"
if ! nix eval --no-write-lock-file "path:$TMP_DIR/downstream-flake-pass#packages.x86_64-linux.dummy.drvPath" 2>/dev/null >/dev/null; then
  echo "Failed: rejected"
  exit 1
fi

echo "Testing legacy nix without allowlist"
if nix eval --impure --expr "(import \"$TMP_DIR/downstream-legacy-fail/default.nix\" { repo_root = \"$REPO_ROOT\"; })" 2>/dev/null; then
  echo "Failed: leaked"
  exit 1
fi

echo "OK"
