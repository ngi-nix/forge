{
  lib,
  config,
  pkgs,
  sharedBuildAttrs,
  ...
}:
{
  imports = [ ./options.nix ];
  config = lib.mkIf config.build.pythonAppBuilder.enable {
    result.derivation = pkgs.python3Packages.buildPythonApplication (
      finalAttrs:
      {
        inherit (config) pname version;
        inherit (config.build.pythonAppBuilder.packages)
          build-system
          dependencies
          optional-dependencies
          ;
        inherit (config.build.pythonAppBuilder)
          disabledTests
          ;
        format = "pyproject";
        src = sharedBuildAttrs.pkgSource config;
        patches = config.source.patches;
        nativeBuildInputs = config.build.pythonAppBuilder.packages.build;
        buildInputs = config.build.pythonAppBuilder.packages.run;
        nativeCheckInputs = config.build.pythonAppBuilder.packages.check;
        # Warning(usability): users may want to disable tests in one setting, ie. without erasing them.
        doCheck = config.build.pythonAppBuilder.packages.check != [ ];
        # Warning(consistency): such renames are not done elsewhere,
        # eg. in `packages.${config}.build.npmPackageBuilder.npmDepsHash`
        pythonImportsCheck = config.build.pythonAppBuilder.importsCheck;
        pythonRelaxDeps = config.build.pythonAppBuilder.relaxDeps;
        passthru = sharedBuildAttrs.pkgPassthru config finalAttrs.finalPackage;
        meta = sharedBuildAttrs.pkgMeta config;
      }
      // config.build.extraAttrs
      // lib.optionalAttrs config.build.debug sharedBuildAttrs.debugShellHookAttr
    );
  };
}
