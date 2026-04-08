#!/usr/bin/env bash

echo "Installing Nix-Portable..."
wget -nv https://github.com/DavHau/nix-portable/releases/download/v012/nix-portable-x86_64
mv nix-portable-x86_64 nix-portable
chmod +x nix-portable

# Netlify automatically provides the current commit hash in the COMMIT_REF env var
commit="${COMMIT_REF:-master}"
sed -i "s/master/$commit/g" ui/src/Main/Config.elm

# set baseUrl to "/"
echo "Configuring routing for root path..."
sed -i "s|:baseUrl|/|g" ui/src/Main/Route.elm
# ui/src/index.html already sets / as base

echo "Building UI..."
export NP_GIT="$(which git)"
export NP_RUNTIME=bwrap
out="$(./nix-portable nix build .#_forge-ui --accept-flake-config --print-out-paths)"

echo "Preparing deployment artifact..."
# The "result" symlink only valid inside the nix-portable sandbox
# credit to: Joachim Breitner - https://discourse.nixos.org/t/use-nix-in-netlify/17695/15
./nix-portable nix run \
  nixpkgs#coreutils -- --coreutils-prog=cp -rL "$out/." ui/build
