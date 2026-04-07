#!/usr/bin/env bash
# Build resources directory for development mode

# Error handling: always exit successfully to not break dev-ui startup
trap 'echo "Error in build-app-resources.sh at line $LINENO"; exit 0' ERR

set -euo pipefail

# Get root directory relative to this script location
# This script is at: flake/develop/commands/dev/dev-ui/build-app-resources.sh
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rootDir="$(cd "$scriptDir/../../../../.." && pwd)"
buildDir="$rootDir/ui/build"
resourcesDir="$buildDir/resources"
configFile="$buildDir/forge-config.json"

mkdir -p "$resourcesDir/apps"

# Copy default icon
cp "$rootDir/ui/src/app-icon.svg" "$resourcesDir/apps/app-icon.svg"

# Read forge-config.json and create app icon directories
# Check if file exists and is readable (follows symlinks)
if [ -e "$configFile" ] && [ -r "$configFile" ]; then
  # Extract app names from forge-config.json
  app_names=$(jq -r '.apps[]?.name // empty' "$configFile" 2>/dev/null || echo "")
  app_count=0

  if [ -n "$app_names" ]; then
    while IFS= read -r app_name; do
      if [ -n "$app_name" ]; then
        # Remove -app suffix for directory name
        app_dir="${app_name%-app}"
        mkdir -p "$resourcesDir/apps/$app_dir"

        # Always use default icon for now
        cp "$rootDir/ui/src/app-icon.svg" "$resourcesDir/apps/$app_dir/icon.svg"
        app_count=$((app_count + 1))
      fi
    done <<< "$app_names"
  fi

  echo "[build-app-resources] Created $app_count app icon(s) in $resourcesDir"
else
  echo "[build-app-resources] forge-config.json not found, only default icon copied"
fi

exit 0
