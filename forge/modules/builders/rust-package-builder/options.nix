# From Nixpkgs' buildRustPackage:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/rust/build-rust-package/default.nix

{
  lib,
  ...
}:
{
  options.build.rustPackageBuilder = {
    enable = lib.mkEnableOption ''
      Rust package builder for applications and libraries.

      Uses `rustPlatform.buildRustPackage` from Nixpkgs, which builds Rust
      packages using Cargo with a vendored dependency set locked by `Cargo.lock`.

      For more information, see the
      [Nixpkgs Rust documentation](https://nixos.org/manual/nixpkgs/unstable/#rust)
    '';

    packages = {
      build = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of build-time dependencies needed during compilation (native architecture).

          Mapped to `nativeBuildInputs`.
        '';
        example = lib.literalExpression "[ pkgs.pkg-config pkgs.rustPlatform.bindgenHook ]";
      };
      run = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of runtime dependencies needed by the package (target architecture).

          Mapped to `buildInputs`.
        '';
        example = lib.literalExpression "[ pkgs.openssl pkgs.sqlite pkgs.libopus ]";
      };
      check = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of test dependencies needed to run the test suite.

          Mapped to `nativeCheckInputs`.
        '';
        example = lib.literalExpression "[ pkgs.cargo-nextest ]";
      };
    };

    cargoHash = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Hash of the Cargo dependencies vendored from `Cargo.lock`.

        Leave empty initially to let Nix print the correct hash on first build.

        Mapped to `cargoHash`.
      '';
      example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    cargoBuildFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional flags passed to `cargo build`.

        Mapped to `cargoBuildFlags`.
      '';
      example = lib.literalExpression ''[ "--features" "enable-feature" ]'';
    };
  };
}
