{
  lib,
  pkgs,
  ...
}:
{
  pkgs.signaturepdf = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.signaturepdf;
    };
  };
  apps.signaturepdf = {
    displayName = "Signature PDF";
    description = "Self-hosted tool to add signature to PDFs.";
    categories = with lib.categories; [ Development ];
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
