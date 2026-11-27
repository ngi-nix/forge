{
  forgeApps,
  pkgs,
  lib,
}:

lib.mapAttrs (
  appName: app:

  let
    info = {
      NAME = app.displayName;
      APP_URL = "https://ngi.nixos.org/app/${app.name}";

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

      JITSI_URL = "https://jitsi.lassul.us/ngi-nix-office-hours";
      CALENDAR_URL = "https://calendar.google.com/calendar/u/0/embed?src=b9o52fobqjak8oq8lfkhg3t0qg@group.calendar.google.com";
      MATRIX_URL = "https://matrix.to/#/#ngi-forge:matrix.org";
      TEAM_URL = "https://nixos.org/community/teams/ngi";
      NIX_URL = "https://nix.dev";
      SURVEY_URL = "https://cryptpad.ngi.nixos.org/form/#/2/form/view/3X1lzb3+XxsLUq-TygwGn-R3aHcvwuNo3L7Ya8Z1VWo/";
      MASTODON_URL = "https://mastodon.social/@ngiforge";
    };

    discourse = with info; ''
      Target audience: NixOS community (is it in Nixpkgs? is there a module?)

      Title: ${NAME} packaged in Nixpkgs and NGI Forge

      Category: NGI Zero

      Body:

      [${NAME}](${HOMEPAGE_URL}) is a ${SUMMARY}.

      <ADD_SCREENSHOT>

      <WHAT_CAN_PEOPLE_DO_WITH_IT>

      <RUN_COMMANDS, e.g. Run it with:

      # nix shell github:ngi-nix/forge#${app.outputName}
      >

      Or visit the [application page](${APP_URL}) for more instructions.

      ### Links

      ${lib.optionalString (app.links != { }) "- Project Details\n${LINKS}"}
      - [NGI Forge tracking issue](<LINK_TO_TRACKING_ISSUE>)
      - [Nixpkgs PR](<LINK_TO_NIXPKGS_PR>)

      You can join this effort by:

      - attending the [office hours on Jitsi](${JITSI_URL}) every [Tuesday and Thursday from 15:00--16:00 CET/CEST](${CALENDAR_URL})
      - contributing to the conversation in the [NGI Forge Matrix channel](${MATRIX_URL})
      - following [NGI Forge on the Fediverse](${MASTODON_URL})
      - participating in [Summer of Nix](https://github.com/ngi-nix/summer-of-nix).

      ---

      This work has been done by @<PACKAGER_DISCOURSE_HANDLE> as part of the [Nix@NGI packaging effort](${TEAM_URL}), funded by [NLnet](https://nlnet.nl) under the NGI0 ${GRANT_STR} grant(s).

      <OTHER_COMMENTS> <THANKS_PEOPLE_INVOLVED>'';

    project-author = with info; ''
      To: Project author
      Cc: NLnet project's email

      Subject: ${NAME} packaged with Nix

      Body:

      Dear <PROJECT_AUTHOR>,

      We are the Nix@NGI team, an NLnet partner for packaging NGI-funded projects.

      We'd like to inform you that ${NAME} has been packaged and is now available in:
      ${APP_URL}.
      There you can find instructions to run ${NAME} in a <AVAILABLE_RUNTIMES>
      <IF_DEPLOY_INSTRUCTIONS, and/or deploy it>.

      We'd value your feedback through the survey linked in the application page,
      but no action is needed from your side.

      Thank you for your work on ${NAME}. We hope this packaging effort makes it
      more accessible to a broader user base.

      Kind regards'';

    github-discussion = with info; ''
      Target audience: Project author(s).

      Category: Packaged projects

      Title: ${NAME} packaged with Nix

      Body:

      Hi @<PROJECT_MAINTAINER_GH-HANDLE_1..N>,

      ${NAME} is now packaged and available on [NGI Forge](${APP_URL}).

      From the application page, you can follow the instructions to run ${NAME} in a <AVAILABLE_RUNTIMES> <IF_DEPLOY_INSTRUCTIONS, and/or deploy it>.

      You know ${NAME} best: <SPECIFIC_QUESTION, e.g. "did we enable the features you'd expect?" or "are the default settings what you'd recommend?">

      For specific requests, comment on <LINK_TO_TRACKING_ISSUE>. If you'd rather not be pinged, just say so.

      Thank you all for your work on ${NAME}!'';

    mastodon-post = with info; ''
      Target audience: Broader open source community

      Post:

      ${NAME} / <@IF_PROJECTS_FEDIVERSE_ADD_HANDLE> packaged with Nix <PROJECT_RELATED_ICON>!

      ${NAME} is a ${SUMMARY}.

      <WHAT_CAN_PEOPLE_DO_WITH_IT>

      Visit ${APP_URL} and follow the instructions to try it out!

      <ADD_SCREENSHOT + ALT_TEXT>

      #NixOS #NLnet #NGI <#OTHER_RELATED_TAGS: use 3 to 5 tags total as more are considered spam>'';
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


      # GitHub Discussions

      \`\`\`text
      ${github-discussion}
      \`\`\`


      # Mastodon post

      \`\`\`text
      ${mastodon-post}
      \`\`\`
      EOF
    '';
  }
) forgeApps
