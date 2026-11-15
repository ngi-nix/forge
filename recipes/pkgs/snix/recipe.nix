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
    version = "0.1.0";
    description = "Modern Rust re-implementation of the components of the Nix package manager.";
    homePage = "https://snix.dev";
    license = lib.licenses.mit;

    source = {
      git = "git:https://git.snix.dev/snix/snix.git?rev=6e990352dd1fe25248a9b47ca61e5b90cc829faf";
      hash = "sha256-LOkDqGsu6oyw/AyHScLOntTzKTaQbNqagw3Wlym5Y0I=";
    };

    build.builders.rust = {
      enable = true;
      cargoHash = "sha256-L6xQcfjo9buZzCZ4rFhCifrRKNxBOg/I8KYKfBo0cTE=";
      packages = with pkgs; {
        build = [
          pkg-config
          protobuf
        ];
        run = [
          zstd
        ];
      };
    };

    build.extraAttrs = {
      patches = [
        ./0001-fix-ui-test.patch
      ];

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
