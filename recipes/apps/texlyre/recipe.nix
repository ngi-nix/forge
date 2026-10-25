{
  forge-lib,
  lib,
  pkgs,
  ...
}:
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
        caption = "Editor with LaTeX code and the compiled PDF";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/collab_cursor_zoomed.png";
        caption = "Users editing a document at the same time";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/chat_zoomed.png";
        caption = "Chat panel";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/review_comment_panel.png";
        caption = "Tracked changes in the review panel";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/error_parser_zoomed_latex.png";
        caption = "LaTeX compilation errors";
      }
      {
        url = "https://raw.githubusercontent.com/texlyre/texlyre/main/showcase/project_viewer_zoomed.png";
        caption = "Project dashboard";
      }
    ];
    usage = ''
      TeXlyre is a local-first, real-time LaTeX and Typst collaboration platform.
      Documents are stored locally in the browser (IndexedDB) and synchronized
      with collaborators peer-to-peer over WebRTC, so editing keeps working
      offline.

      Web interface: [http://localhost:3000](http://localhost:3000)
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
          ports = [ "3000:3000" ];
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
