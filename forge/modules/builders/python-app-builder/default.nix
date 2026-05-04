{
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
          type = lib.types.attrsOf (lib.types.submoduleWith { modules = [ ./options.nix ]; });
        };

        config = {
          packages =
            let
              composePkg =
                pkgName: pkg:
                pkgs.callPackage (
                  # Derivation start
                  { }:
                  pkgs.python3Packages.buildPythonApplication (
                    finalAttrs:
                    {
                      pname = pkg.name;
                      version = pkg.version;
                      format = "pyproject";
                      src = sharedBuildAttrs.pkgSource pkg;
                      patches = pkg.source.patches;
                      build-system = pkg.build.pythonAppBuilder.packages.build-system;
                      nativeBuildInputs = pkg.build.pythonAppBuilder.packages.build;
                      buildInputs = pkg.build.pythonAppBuilder.packages.run;
                      dependencies = pkg.build.pythonAppBuilder.packages.dependencies;
                      optional-dependencies = pkg.build.pythonAppBuilder.packages.optional-dependencies;
                      nativeCheckInputs = pkg.build.pythonAppBuilder.packages.check;
                      doCheck = pkg.build.pythonAppBuilder.packages.check != [ ];
                      pythonImportsCheck = pkg.build.pythonAppBuilder.importsCheck;
                      pythonRelaxDeps = pkg.build.pythonAppBuilder.relaxDeps;
                      disabledTests = pkg.build.pythonAppBuilder.disabledTests;
                      passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                      meta = sharedBuildAttrs.pkgMeta pkg;
                    }
                    // pkg.build.extraAttrs
                    // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
                  )
                  # Derivation end
                ) { };
              enabledPkgs = lib.filterAttrs (name: p: p.build.pythonAppBuilder.enable) config.forge.packages;

              pythonAppBuilderPkgs = lib.mapAttrs composePkg enabledPkgs;
            in
            pythonAppBuilderPkgs;
        };
      }
    );
  };
}
