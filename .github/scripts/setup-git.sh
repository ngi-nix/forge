#!/usr/bin/env bash

set -euo pipefail

git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"
git config --global credential.helper "!gh auth git-credential"
