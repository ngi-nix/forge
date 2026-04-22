#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./maintainers/mk-announcement.sh --app <APP_NAME>

APP=""

while (($#)); do
  case "$1" in
  -a | --app)
    APP="$2"
    shift 2
    ;;
  *) shift ;;
  esac
done

if [[ -z $APP ]]; then
  echo "Error: --app <APP_NAME> is required" >&2
  exit 1
fi

system=$(nix eval --raw 'nixpkgs#stdenv.hostPlatform.system')

json_content=$(
  nix build ".#packages.${system}._forge-config" --no-link --print-out-paths |
    xargs jq ".apps[] | select(.name == \"$APP\")"
)

APP_URL="https://ngi-nix.github.io/forge/app/$APP/"
JITSI_URL="https://jitsi.lassul.us/ngi-nix-office-hours"
CALENDAR_URL="https://calendar.google.com/calendar/u/0/embed?src=b9o52fobqjak8oq8lfkhg3t0qg@group.calendar.google.com"
MATRIX_URL="https://matrix.to/#/#ngipkgs:matrix.org"
TEAM_URL="https://nixos.org/community/teams/ngi/"
NIX_URL="https://nix.dev/"

NAME=$(jq -r '.displayName' <<<"$json_content")
summary=$(jq -r '.description | rtrimstr(".") as $s | ($s[0:1] | ascii_downcase) + $s[1:]' <<<"$json_content")
homepage_url=$(jq -r '
    if .links.website != null then .links.website.url
    elif .links.source != null then .links.source.url
    else "<ADD_HOMEPAGE_URL>"
    end
' <<<"$json_content")
grant_str=$(jq -r '[.ngi.grants | to_entries[] | select(.value | length > 0) | .key] | join(", ")' <<<"$json_content")

cat <<EOF
# Discourse post

\`\`\`text
Title: [Nix@NGI] $NAME packaged for NGI Forge

[**$NAME**]($homepage_url) is a $summary. This project is funded by the NGI0 $grant_str grant(s).

<WHAT_CAN_PEOPLE_DO_WITH_IT>

<OTHER_COMMENTS> <THANKS_PEOPLE_INVOLVED>

<LINK_TO_TRACKING_ISSUE>

### Try it out

Visit the [application]($APP_URL) and launch $NAME in a shell environment, container, or NixOS VM.

### Share your feedback

Please leave your feedback using this [short survey](<LINK_TO_SURVEY>), which will be available for the next 30 days (until the <ADD_ABSOLUTE_DATE>).

Alternatively, join the [office hours on Jitsi]($JITSI_URL) every [Tuesday and Thursday from 15:00--16:00 CET/CEST]($CALENDAR_URL) and the [NGIpkgs Matrix channel]($MATRIX_URL) for any further comments or questions.

[Nix@NGI team webpage]($TEAM_URL).
\`\`\`

---

# Email to NLnet

\`\`\`text
Subject: [Nix@NGI] $NAME packaged for NGI Forge

Body:

Dear NLnet Foundation staff,

We have completed the packaging tasks for the following project:
- Project: $NAME
- Project number: <ADD_PROJECT_NUMBER>
- Fund: $grant_str

The package is now available in the NGI Forge repository: $APP_URL.

The Nix@NGI team: $TEAM_URL.

Kind regards
\`\`\`

---

# Email to project author

\`\`\`text
Subject: [Nix@NGI] $NAME packaged for NGI Forge

Body:

Dear <PROJECT_AUTHOR>,

The Nix@NGI team is an NLnet partner for packaging NGI0 funded projects. We are happy to let you know that we have packaged $NAME for the NGI Forge repository. Visit the application page at $APP_URL and launch $NAME in a shell environment, container, or NixOS VM.

Your input as the project author is very valuable for us. If you can, please leave your feedback using this short survey: <LINK_TO_SURVEY>, which will be available for the next 30 days.

For more information about Nix, see: $NIX_URL.

The Nix@NGI team: $TEAM_URL.

Kind regards
\`\`\`
EOF
