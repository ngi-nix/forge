{
  forgeApps,
  pkgs,
  lib,
}:

lib.mapAttrs (
  appName: app:

  let
    info = {
      APP_URL = "https://ngi.nixos.org/app/${app.name}";
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

      LINKS =
        let
          appLinks = lib.filterAttrs (_: link: link != null) app.links;
        in
        lib.concatMapAttrsStringSep "\n" (
          name: value:
          if name == "website" then
            "  - [Website](${value})"
          else if name == "docs" then
            "  - [Documentation](${value})"
          else if name == "source" then
            "  - [Source Repository](${value})"
          else
            value
        ) appLinks;
    };

    discourse = with info; ''
      Title: [Nix@NGI] ${NAME} packaged for NGI Forge

      [**${NAME}**](${HOMEPAGE_URL}) is a ${SUMMARY}.

      <WHAT_CAN_PEOPLE_DO_WITH_IT>

      ### Try it out

      Visit the [application page](${APP_URL}), launch ${NAME} in a shell environment, container, or NixOS VM and follow the usage instructions.

      ### Links

      ${lib.optionalString (app.links != { }) "- Project Details\n${LINKS}"}
      - [NGI Forge Tracking Issue](<LINK_TO_TRACKING_ISSUE>)
      - [Nixpkgs PR](<LINK_TO_NIXPKGS_PR>)

      ### Share your feedback

      We’d like to hear from you, so please leave your feedback using this [short survey](${SURVEY_URL}).

      Alternatively, you can join the:

      - [office hours on Jitsi](${JITSI_URL}) every [Tuesday and Thursday from 15:00--16:00 CET/CEST](${CALENDAR_URL})
      - [NGIpkgs Matrix channel](${MATRIX_URL})

      for any further comments or questions.

      ---

      This work has been done by @<PACKAGER_NAME> as part of the [Nix@NGI packaging effort](https://nixos.org/community/teams/ngi), funded by [NLnet](https://nlnet.nl) under the NGI0 ${GRANT_STR} grant(s).

      <OTHER_COMMENTS> <THANKS_PEOPLE_INVOLVED>'';

    project-author = with info; ''
      Subject: [Nix@NGI] ${NAME} packaged for NGI Forge

      Body:

      Dear <PROJECT_AUTHOR>,

      We are the Nix@NGI team, an NLnet partner for packaging NGI0-funded projects.

      We are pleased to inform you that ${NAME} has been successfully packaged for NixOS and is now available in our NGI Forge repository:
      ${APP_URL}

      From there, it can be launch in a shell environment, container, or NixOS VM with a single command.

      As the project authors, your feedback is invaluable to us. If you have a few minutes, we would greatly appreciate your thoughts through this short survey:
      ${SURVEY_URL}

      Thank you for your work on ${NAME}. We hope this packaging effort makes it more accessible to the broader NixOS community.

      For more information about Nix, see: ${NIX_URL}.

      Kind regards,
      The Nix@NGI Team
      ${TEAM_URL}'';
  in

  pkgs.writeShellApplication {
    name = "announce-project";
    text = ''
      cat <<EOF
      # Discourse post

      \`\`\`text
      ${discourse}
      \`\`\`


      # Email to project author

      \`\`\`text
      ${project-author}
      \`\`\`
      EOF
    '';
  }
) forgeApps
