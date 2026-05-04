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

              pythonPackageBuilderPkgs = lib.listToAttrs (
                map (pkg: {
                  name = pkg.name;
                  value = pkgs.callPackage (
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
                }) (lib.filter (p: p.build.pythonPackageBuilder.enable == true) cfg)
              );
            in
            pythonPackageBuilderPkgs;
        };
      }
    );
  };
}
