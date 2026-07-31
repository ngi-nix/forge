#!/usr/bin/env bash
set -euo pipefail

# Usage: ./maintainers/mk-nixpkgs-build-failure-issue.sh <package-name> <hydra-build-job-url> <ngi-project-issue-url>
#
# Options:
#   package-name:           full attribute name of failing package.
#                           Example: aerogramme
#
#   hydra-build-job-url:    Hydra build job URL.
#                           Example: https://hydra.nixos.org/build/338636531
#
#   ngi-project-issue-url:  NGI project tracking issue.
#                           Example: https://github.com/ngi-nix/projects/issues/103

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <package-name> <hydra-build-job-url> <ngi-project-issue-url>" >&2
  exit 1
fi

package_name="$1"
hydra_build_job_url="$2"
ngi_project_issue_url="$3"

nixpkgs_repo="nixos/nixpkgs"

# NixOS/NGI project board (https://github.com/orgs/NixOS/projects/117)
ngi_board_owner="NixOS"
ngi_board_number="117"
ngi_board_status_field_id="PVTSSF_lADOAAdwkM4Be7s4zhZSSyU"
ngi_board_status_in_progress_option_id="47fc9ee4"

# Create Nixpkgs issue
issue_url=$(gh issue create \
  --repo "$nixpkgs_repo" \
  --title "Build failure: ${package_name}" \
  --label "0.kind: build failure" \
  --label "6.topic: NLnet / NGI" \
  --body "$(
    cat <<EOF
### Nixpkgs version

- Unstable (latest)

### Steps to reproduce

1. \`nix-build -A ${package_name}\`

### Can Hydra reproduce this build failure?

Yes, Hydra can reproduce this build failure.

### Link to Hydra build job

${hydra_build_job_url}

### Relevant log output

See log output in Hydra build job above.

### Additional context

-

### System metadata

-

### Notify maintainers

@NixOS/ngi

### I assert that this issue is relevant for Nixpkgs

- [x] I assert that this is a bug and not a support request.
- [x] I assert that this is not a duplicate of an existing issue.
- [x] I assert that I have read the NixOS Code of Conduct and agree to abide by it.
- [x] I assert that I have read the automation/AI policy and that this issue report complies with it.
EOF
  )")

echo "Created issue ${issue_url}"

# Add issue under NGI Project tracking issue
gh issue edit "$issue_url" --parent "$ngi_project_issue_url"

echo "Added as sub-issue of ${ngi_project_issue_url}"

# Add issue to NGI board, set to "In Progress"
item_id=$(gh project item-add "$ngi_board_number" \
  --owner "$ngi_board_owner" \
  --url "$issue_url" \
  --format json --jq '.id')

gh project item-edit \
  --id "$item_id" \
  --project-id "$(gh project view "$ngi_board_number" --owner "$ngi_board_owner" --format json --jq '.id')" \
  --field-id "$ngi_board_status_field_id" \
  --single-select-option-id "$ngi_board_status_in_progress_option_id"

echo "Added to NGI board (https://github.com/orgs/${ngi_board_owner}/projects/${ngi_board_number}) as In Progress"
