{
  forge-lib,
  lib,
  config,
  pkgs,
  ...
}:
let
  app = config.apps.texlyre;
in
{
  pkgs.texlyre = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.texlyre;
    };
  };

  apps.texlyre = {
    displayName = "Texlyre";
    description = "Local-first real-time LaTeX and Typst collaboration platform with offline editing capabilities.";
    categories = with forge-lib.categories; [
      Office
      P2P
    ];
    screenshotSources.urls = [
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/main_showcase_dark.png";
        caption = "Main editor interface showing split view with LaTeX code on left, compiled PDF on right";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/collab_cursor_zoomed.png";
        caption = "Multiple users editing simultaneously with different colored cursors";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/chat_zoomed.png";
        caption = "Collaborators using the chat panel to discuss progress";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/review_comment_panel.png";
        caption = "TeXlyre editor with tracked edits and the review panel open";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/error_parser_zoomed_latex.png";
        caption = "LaTeX compilation in progress with error panel and PDF output";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/project_viewer_zoomed.png";
        caption = "Project dashboard with file explorer and project cards";
      }
    ];
    usage = ''
      TeXlyre is a local-first, real-time LaTeX and Typst collaboration platform.
      Documents are stored locally in the browser (IndexedDB) and synchronized
      with collaborators peer-to-peer over WebRTC, so editing keeps working
      offline.

      Web interface: [http://localhost:${toString app.services.components.texlyre.endpoints.web.forwardedPort}](http://localhost:${toString app.services.components.texlyre.endpoints.web.forwardedPort})
    '';

    links = {
      website = "https://texlyre.github.io";
      source = "https://github.com/texlyre/texlyre";
      docs = "https://texlyre.github.io/docs/intro";
    };

    ngi.grants = {
      Commons = [
        "Texlyre"
      ];
    };

    icon = ./icon.svg;

    services = {
      components.texlyre = {
        process = {
          command = pkgs.texlyre;
        };
        endpoints = {
          web = {
            port = 3000;
          };
        };
      };
      runtimes.container.enable = true;
      runtimes.nixos.enable = true;
    };

    test.services.script = ''
      curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"
      $curl localhost:3000 | grep "TeXlyre"
    '';
  };
}
