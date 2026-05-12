{
  specialArgs,
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
          type = lib.types.attrsOf (
            lib.types.submoduleWith {
              modules = [ ./options.nix ];
            }
          );
        };

        config = {
          packages =
            let
              composePkg =
                pkgName: pkg:
                pkgs.callPackage (
                  # Derivation start
                  { }:
                  pkgs.python3Packages.buildPythonPackage (
                    finalAttrs:
                    {
                      pname = pkg.name;
                      version = pkg.version;
                      format = "pyproject";
                      src = sharedBuildAttrs.pkgSource pkg;
                      patches = pkg.source.patches;
                      build-system = pkg.build.pythonPackageBuilder.packages.build-system;
                      nativeBuildInputs = pkg.build.pythonPackageBuilder.packages.build;
                      buildInputs = pkg.build.pythonPackageBuilder.packages.run;
                      dependencies = pkg.build.pythonPackageBuilder.packages.dependencies;
                      optional-dependencies = pkg.build.pythonPackageBuilder.packages.optional-dependencies;
                      nativeCheckInputs = pkg.build.pythonPackageBuilder.packages.check;
                      doCheck = pkg.build.pythonPackageBuilder.packages.check != [ ];
                      pythonImportsCheck = pkg.build.pythonPackageBuilder.importsCheck;
                      pythonRelaxDeps = pkg.build.pythonPackageBuilder.relaxDeps;
                      disabledTests = pkg.build.pythonPackageBuilder.disabledTests;
                      passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                      meta = sharedBuildAttrs.pkgMeta pkg;
                    }
                    // pkg.build.extraAttrs
                    // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
                  )
                  # Derivation end
                ) { };

              enabledPkgs = lib.filterAttrs (name: p: p.build.pythonPackageBuilder.enable) config.forge.packages;

              pythonPackageBuilderPkgs = lib.mapAttrs composePkg enabledPkgs;
            in
            pythonPackageBuilderPkgs;
        };
      }
    );
  };
}
