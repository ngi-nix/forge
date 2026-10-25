{
  forge-lib,
  lib,
  pkgs,
  ...
}:
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
    screenshotSources.urls = [
      {
        url = "https://github.com/24eme/signaturepdf/assets/71143205/c3e8b8d2-3f94-45a3-a8fd-143077443337";
        caption = "Signature feature";
      }
      {
        url = "https://github.com/24eme/signaturepdf/assets/71143205/4deeb6fb-caa9-4365-895e-d22177a6ec3b";
        caption = "Signature feature";
      }
      {
        url = "https://github.com/24eme/signaturepdf/assets/71143205/800c45a4-4c4c-42d5-b09b-c81cfcc0e6e0";
        caption = "Organizing feature";
      }
      {
        url = "https://github.com/24eme/signaturepdf/assets/71143205/a008d765-3a74-4ab4-b2bc-4af6c81575fe";
        caption = "Organizing feature";
      }
      {
        url = "https://github.com/24eme/signaturepdf/assets/71143205/1f195bae-4af3-4d7b-9e31-3acd7552c2eb";
        caption = "Metadata feature";
      }
    ];
    usage = ''
      Signature PDF is a web application for signing PDFs, alone or with
      others, as well as organizing pages (merge, sort, rotate, delete,
      extract), editing metadata, and compressing PDF files.

      Web interface: [http://localhost:8080](http://localhost:8080)
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
          ports = [
            "8080:8080"
          ];
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
