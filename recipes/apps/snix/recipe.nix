{
  lib,
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.snix;
in
{
  apps.snix = {
    displayName = "Snix";
    description = "Modern Rust re-implementation of the components of the Nix package manager.";
    categories = with lib.categories; [ Development ];
    usage = ''
      Snix is a modular, early-stage reimplementation of Nix's components in
      Rust. It is not a full-featured drop-in replacement for Nix, and none of
      its current APIs or CLIs are considered stable.

      This package provides several binaries, including:

      - `snix-store` — run a gRPC daemon exposing the Snix store, import or
        copy store paths, or mount it via FUSE/virtiofs.
      - `snix-nar-bridge` — a read-write Nix HTTP Binary Cache endpoint backed
        by the Snix store, allowing Nix to substitute from and copy into it.
      - `snix-nix-daemon` — implements the Nix daemon protocol.
      - `snix-eval`, `snix-build`, `snix-castore`, `snix-castore-http`,
        `snix-derivation-show` — additional tools covering evaluation,
        building, and low-level store/derivation inspection.

      Run any binary with `--help` to see its available options, as
      documentation for individual commands is still incomplete.

      See the [Docs](${recipe.links.docs}) for architecture and
      component-level details.
    '';

    links = {
      website = "https://snix.dev";
      source = "https://git.snix.dev/snix/snix";
      docs = "https://snix.dev/docs";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Core = [
        "Snix-Store_Builder"
      ];
    };

    programs = {
      mainPackage = pkgs.snix;
      packages = [ pkgs.snix ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      snix-eval -E '1 + 2 * 3' | grep -q '7'
    '';

  };
}
