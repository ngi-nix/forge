{
  forge-lib,
  lib,
  config,
  pkgs,
  ...
}:
let
  app = config.apps.signaturepdf;
in
{
  pkgs.signaturepdf = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.signaturepdf;
    };
  };
  apps.signaturepdf = {
    displayName = "Signature PDF";
    description = "Self-hosted tool to add signature to PDFs.";
    categories = with forge-lib.categories; [
      Development
      Office
    ];
    screenshots = [
      {
        url = "https://github.com/24eme/signaturepdf/assets/71143205/4deeb6fb-caa9-4365-895e-d22177a6ec3b";
        hash = "sha256-YJQoCmgd833SnODDY38ChfqByRlbZwh2VQOWi5kkpWk=";
        caption = "Add a signature, initials, a stamp, text or check boxes to a PDF";
      }
      {
        url = "https://github.com/24eme/signaturepdf/assets/71143205/a008d765-3a74-4ab4-b2bc-4af6c81575fe";
        hash = "sha256-BQLgiBEKvgi/FtJCznEhCwV0hieSmUNGzNvSnBxyoRI=";
        caption = "Merge, sort, rotate, delete and extract pages";
      }
      {
        url = "https://github.com/24eme/signaturepdf/assets/71143205/1f195bae-4af3-4d7b-9e31-3acd7552c2eb";
        hash = "sha256-tX8uOnTVl2TR2B5Y/MUil5YzQBOuiltMrXdR5yGq9aY=";
        caption = "Edit the metadata of a PDF";
      }
      {
        url = "https://github.com/24eme/signaturepdf/assets/71143205/7d0e93a3-5567-4545-9c43-033b9028b036";
        hash = "sha256-u8z3II7dqlODkyUkLaaUavxZCJIdgA3N66m/nsJ3IL8=";
        caption = "Compress a PDF to reduce its file size";
      }
    ];
    usage = ''
      Signature PDF is a web application for signing PDFs, alone or with
      others, as well as organizing pages (merge, sort, rotate, delete,
      extract), editing metadata, and compressing PDF files.

      Web interface: [http://localhost:${toString app.services.components.signaturepdf.endpoints.web.forwardedPort}](http://localhost:${toString app.services.components.signaturepdf.endpoints.web.forwardedPort})
    '';

    links = {
      website = "https://pdf.24eme.fr";
      source = "https://github.com/24eme/signaturepdf";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "SignaturePDF-UX"
      ];
      Review = [
        "SignaturePDF"
      ];
    };

    services = {
      components.signaturepdf = {
        process = {
          command = pkgs.signaturepdf.overrideAttrs (old: {
            # signaturepdf package binds to localhost only
            # which is not accessible from outside the container
            # We need to change it to bind to 0.0.0.0
            installPhase = builtins.replaceStrings [ "localhost:\$port" ] [ "0.0.0.0:\$port" ] old.installPhase;
          });
          argv = [
            "8080"
          ];
        };
        endpoints = {
          web = {
            port = 8080;
          };
        };
      };

      runtimes.container.enable = true;
      runtimes.nixos.enable = true;
    };

    test.services.script = ''
      curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"
      $curl localhost:8080 | grep "Signature PDF"
    '';
  };
}
