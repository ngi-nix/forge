{
  lib,
  pkgs,
  config,
  ...
}:
let
  recipe = config.pkgs.snix;
in
{
  pkgs.snix = {
    version = "0-unstable-2026-11-10";
    description = "Modern Rust re-implementation of the components of the Nix package manager.";
    homePage = "https://snix.dev";
    license = lib.licenses.mit;

    source = {
      git = "git:https://git.snix.dev/snix/snix.git?rev=e6a4f77ea12b8c46779451b7e48f0d334f7d246c";
      hash = "sha256-ZMU90InalYjEe9Uvv0NCNCHNIxKmt4PRcWZ42w272Xk=";
    };

    build.builders.rust = {
      enable = true;
      cargoHash = "sha256-x4b8SNXdvgX9nWchx8Kkp4qefNXuz9pGC9K+g9RU/TU=";
      packages.build = with pkgs; [
        protobuf
      ];
    };

    build.extraAttrs = {
      nativeCheckInputs = [ pkgs.cacert ];

      preCheck = ''
        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
      '';

      # Pulled from the snix dev shell
      env.SNIX_BUILD_SANDBOX_SHELL =
        if pkgs.stdenv.hostPlatform.isLinux then
          lib.getExe' pkgs.busybox-sandbox-shell "busybox"
        else
          "/bin/sh";
      sourceRoot = "${recipe.result.derivation.src.name}/snix";
    };

    test.script = ''
      snix --version | grep -q "${recipe.version}"
    '';
  };
}
