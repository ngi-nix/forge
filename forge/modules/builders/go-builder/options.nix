{
  lib,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Go module builder for applications and libraries.

      Uses `buildGoModule` from Nixpkgs, which builds Go modules using the
      standard Go toolchain with module-aware dependency management.

      For more information, see the
      [Nixpkgs Go documentation](https://nixos.org/manual/nixpkgs/unstable/#sec-language-go)
    '';
    vendorHash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "";
      description = ''
        Hash of the vendored Go module dependency tree.

        Leave empty initially to let Nix print the correct hash on first build.

        Mapped to `vendorHash`.
      '';
      example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    modRoot = lib.mkOption {
      type = lib.types.str;
      default = ".";
      description = ''
        Relative path to the directory containing go.mod.

        Useful for monorepos where the Go module is not at the repository root.

        Mapped to `modRoot`.
      '';
      example = "cmd/my-app";
    };
    subPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of Go packages to build.

        Keep the default for a single main package, or provide multiple package
        paths.

        Mapped to `subPackages`.
      '';
      example = [
        "."
        "./cmd/tool"
      ];
    };
    ldflags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Linker flags passed to the Go compiler.

        Commonly used to embed version information at build time.

        Mapped to `ldflags`.
      '';
      example = [
        "-s"
        "-w"
        "-X main.version=1.0.0"
      ];
    };
    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Build tags passed to the Go compiler.

        Mapped to `tags`.
      '';
      example = [
        "sqlite"
        "netgo"
      ];
    };
    proxyVendor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Fetch dependencies via the Go module proxy instead of vendoring from
        source.

        Enable this only when upstream vendoring is incomplete or unsuitable.

        Mapped to `proxyVendor`.
      '';
      example = true;
    };
  };
}
