{
  forgeApps,
  pkgs,
  lib,
}:

lib.listToAttrs (
  lib.map (
    app:

    let
      info = {
        APP_URL = "https://ngi-nix.github.io/forge/app/${app.name}";
        JITSI_URL = "https://jitsi.lassul.us/ngi-nix-office-hours";
        CALENDAR_URL = "https://calendar.google.com/calendar/u/0/embed?src=b9o52fobqjak8oq8lfkhg3t0qg@group.calendar.google.com";
        MATRIX_URL = "https://matrix.to/#/#ngipkgs:matrix.org";
        TEAM_URL = "https://nixos.org/community/teams/ngi";
        NIX_URL = "https://nix.dev";
        SURVEY_URL = "https://nixos-foundation.notion.site/35759d49e1be81edb478e3aade9f8e95?pvs=105";
        NAME = app.displayName;

        SUMMARY = lib.pipe app.description [
          (lib.strings.removeSuffix ".")
          # lower first char
          (s: (lib.toLower (lib.substring 0 1 s)) + (lib.substring 1 (-1) s))
        ];

        HOMEPAGE_URL =
          if app.links.website != null then
            app.links.website
          else if app.links.source != null then
            app.links.source
          else
            "<ADD_HOMEPAGE_URL>";

        GRANT_STR = lib.pipe app.ngi.grants [
          (lib.filterAttrs (_: v: v != [ ]))
          (lib.attrNames)
          (lib.strings.concatStringsSep ", ")
        ];
      };

      discourse = with info; ''
        Title: [Nix@NGI] ${NAME} packaged for NGI Forge

        [**${NAME}**](${HOMEPAGE_URL}) is a ${SUMMARY}.
        This project is funded by the NGI0 ${GRANT_STR} grant(s).

        <WHAT_CAN_PEOPLE_DO_WITH_IT>

        <OTHER_COMMENTS> <THANKS_PEOPLE_INVOLVED>

        <LINK_TO_TRACKING_ISSUE>

        ### Try it out

        Visit the [application](${APP_URL}) and launch ${NAME} in a shell environment, container, or NixOS VM.

        ### Share your feedback

        Please leave your feedback using this [short survey](${SURVEY_URL}).

        Alternatively, join the [office hours on Jitsi](${JITSI_URL}) every [Tuesday and Thursday from 15:00--16:00 CET/CEST](${CALENDAR_URL}) and the [NGIpkgs Matrix channel](${MATRIX_URL}) for any further comments or questions.

        [Nix@NGI team webpage](${TEAM_URL}).'';

      nlnet = with info; ''
        Subject: [Nix@NGI] ${NAME} packaged for NGI Forge

        Body:

        Dear NLnet Foundation staff,

        We have completed the packaging tasks for the following project:
        - Project: ${NAME}
        - Project number: <ADD_PROJECT_NUMBER>
        - Fund: ${GRANT_STR}

        The package is now available in the NGI Forge repository: ${APP_URL}.

        The Nix@NGI team: ${TEAM_URL}.

        Kind regards'';

      project-author = with info; ''
        Subject: [Nix@NGI] ${NAME} packaged for NGI Forge

        Body:

        Dear <PROJECT_AUTHOR>,

        The Nix@NGI team is an NLnet partner for packaging NGI0 funded projects. We are happy to let you know that we have packaged ${NAME} for the NGI Forge repository. Visit the application page at ${APP_URL} and launch ${NAME} in a shell environment, container, or NixOS VM.

        Your input as the project author is very valuable for us. If you can, please leave your feedback using this short survey: ${SURVEY_URL}.

        For more information about Nix, see: ${NIX_URL}.

        The Nix@NGI team: ${TEAM_URL}.

        Kind regards'';
    in

    {
      name = app.name;
      value = pkgs.writeShellApplication {
        name = "announce-project";
        text = ''
          cat <<EOF
          # Discourse post

          \`\`\`text
          ${discourse}
          \`\`\`
          ---

          # Email to NLnet

          \`\`\`text
          ${nlnet}
          \`\`\`
          ---

          # Email to project author

          \`\`\`text
          ${project-author}
          \`\`\`
          EOF
        '';
      };
    }
  ) forgeApps
)
