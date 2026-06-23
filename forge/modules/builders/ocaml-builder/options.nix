{
  lib,
  pkgs,
  ...
}:
{
  options.build.ocamlBuilder = {
    enable = lib.mkEnableOption ''
      OCaml builder for applications and libraries.
      Uses `ocamlPackages.buildDunePackage` from Nixpkgs.

      For more information, see the
      [Nixpkgs OCaml documentation](https://nixos.org/manual/nixpkgs/unstable/#sec-language-ocaml)
    '';

    packages = {
      scope = lib.mkOption {
        type = lib.types.attrs;
        default = pkgs.ocaml-ng.ocamlPackages;
        example = lib.literalExpression "pkgs.ocaml-ng.ocamlPackages_latest";
        description = ''
          The OCaml scope where the builder and dependencies will be passed from.
        '';
      };

      require = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = lib.literalExpression "4.12";
        description = ''
          Minimal required OCaml version to build the package.

          Mapped to `minimalOCamlVersion`.
        '';
      };

      build = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = lib.literalExpression "[ pkgs.ocamlPackages.menhir ]";
        description = ''
          List of build-time dependencies needed during compilation (native
          architecture).

          Mapped to `nativeBuildInputs`.
        '';
      };

      run = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = lib.literalExpression "with pkgs.ocamlPackages; [ cmdliner ppxlib ]";
        description = ''
          List of runtime dependencies needed by the package (target architecture).

          Mapped to `buildInputs`.
        '';
      };

      dep = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = lib.literalExpression "with pkgs.ocamlPackages; [ menhirLib yojson ]";
        description = ''
          List of dependencies that must be propagated to downstream consumers.

          Mapped to `propagatedBuildInputs`.
        '';
      };

      check = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = lib.literalExpression "[ pkgs.ocamlPackages.alcotest ]";
        description = ''
          List of test dependencies needed to run the test suite.

          Mapped to `checkInputs`.
        '';
      };
    };
  };
}
