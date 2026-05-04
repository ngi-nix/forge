{
  inputs,
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
    perSystem = mkPerSystemOption (
      {
        config,
        pkgs,
        sharedBuildAttrs,
        ...
      }:
      {
        options.forge.packages = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule ./options.nix);
        };

        config = {
          packages =
            let
              cfg = config.forge.packages;

              standardBuilderPkgs = lib.listToAttrs (
                map (pkg: {
                  name = pkg.name;
                  value = pkgs.callPackage (
                    # Derivation start
                    { }:
                    pkg.build.standardBuilder.stdenv.mkDerivation (
                      finalAttrs:
                      {
                        pname = pkg.name;
                        version = pkg.version;
                        src = sharedBuildAttrs.pkgSource pkg;
                        patches = pkg.source.patches;
                        nativeBuildInputs = pkg.build.standardBuilder.packages.build;
                        buildInputs = pkg.build.standardBuilder.packages.run;
                        nativeCheckInputs = pkg.build.standardBuilder.packages.check;
                        passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                        meta = sharedBuildAttrs.pkgMeta pkg;
                      }
                      // pkg.build.extraAttrs
                      // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
                    )
                    # Derivation end
                  ) { };
                }) (lib.filter (p: p.build.standardBuilder.enable == true) cfg)
              );
            in
            standardBuilderPkgs;
        };
      }
    );
  };
}
