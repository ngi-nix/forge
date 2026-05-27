{
  lib,
  config,
  pkgs,
  sharedBuildAttrs,
  ...
}:
{
  packages = lib.mapAttrs (
    packageName: package:
    lib.mkIf package.build.pythonAppBuilder.enable (
      pkgs.python3Packages.buildPythonApplication (
        finalAttrs:
        {
          inherit (package) pname version;
          inherit (package.build.pythonAppBuilder.packages)
            build-system
            dependencies
            optional-dependencies
            ;
          inherit (package.build.pythonAppBuilder)
            disabledTests
            ;
          format = "pyproject";
          src = sharedBuildAttrs.pkgSource package;
          patches = package.source.patches;
          nativeBuildInputs = package.build.pythonAppBuilder.packages.build;
          buildInputs = package.build.pythonAppBuilder.packages.run;
          nativeCheckInputs = package.build.pythonAppBuilder.packages.check;
          # Warning(usability): users may want to disable tests in one setting, ie. without erasing them.
          doCheck = package.build.pythonAppBuilder.packages.check != [ ];
          # Warning(consistency): such renames are not done elsewhere,
          # eg. in `packages.${package}.build.npmPackageBuilder.npmDepsHash`
          pythonImportsCheck = package.build.pythonAppBuilder.importsCheck;
          pythonRelaxDeps = package.build.pythonAppBuilder.relaxDeps;
          passthru = sharedBuildAttrs.pkgPassthru package finalAttrs.finalPackage;
          meta = sharedBuildAttrs.pkgMeta package;
        }
        // package.build.extraAttrs
        // lib.optionalAttrs package.build.debug sharedBuildAttrs.debugShellHookAttr
      )
    )
  ) config.forge.packages;
}
