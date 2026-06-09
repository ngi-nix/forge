{
  lib,
  config,
  pkgs,
  sharedBuildAttrs,
  ...
}:
{
  imports = [ ./options.nix ];
  config = lib.mkIf config.build.pythonPackageBuilder.enable {
    result.derivation = pkgs.python3Packages.buildPythonPackage (
      finalAttrs:
      {
        inherit (config) pname version;
        inherit (config.build.pythonPackageBuilder.packages)
          build-system
          dependencies
          optional-dependencies
          ;
        inherit (config.build.pythonPackageBuilder)
          disabledTests
          ;
        format = "pyproject";
        src = sharedBuildAttrs.pkgSource config;
        patches = config.source.patches;
        nativeBuildInputs = config.build.pythonPackageBuilder.packages.build;
        buildInputs = config.build.pythonPackageBuilder.packages.run;
        nativeCheckInputs = config.build.pythonPackageBuilder.packages.check;
        # Warning(usability): users may want to disable tests in one setting, ie. without erasing them.
        doCheck = config.build.pythonPackageBuilder.packages.check != [ ];
        pythonImportsCheck = config.build.pythonPackageBuilder.importsCheck;
        pythonRelaxDeps = config.build.pythonPackageBuilder.relaxDeps;
        passthru = sharedBuildAttrs.pkgPassthru config finalAttrs.finalPackage;
        meta = sharedBuildAttrs.pkgMeta config;
      }
      // config.build.extraAttrs
      // lib.optionalAttrs config.build.debug sharedBuildAttrs.debugShellHookAttr
    );
  };
}
