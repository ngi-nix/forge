#!/usr/bin/env bash

# in dry mode echo back the command, otherwise execute it
debug_run() {
  if [[ ${DRY_RUN:-false} == "true" ]]; then
    echo "  (dry-run) $*"
    return 0
  else
    "$@"
  fi
}
