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
    lib.mkIf package.build.pythonPackageBuilder.enable (
      pkgs.python3Packages.buildPythonPackage (
        finalAttrs:
        {
          inherit (package) pname version;
          inherit (package.build.pythonPackageBuilder.packages)
            build-system
            dependencies
            optional-dependencies
            ;
          inherit (package.build.pythonPackageBuilder)
            disabledTests
            ;
          format = "pyproject";
          src = sharedBuildAttrs.pkgSource package;
          patches = package.source.patches;
          nativeBuildInputs = package.build.pythonPackageBuilder.packages.build;
          buildInputs = package.build.pythonPackageBuilder.packages.run;
          nativeCheckInputs = package.build.pythonPackageBuilder.packages.check;
          # Warning(usability): users may want to disable tests in one setting, ie. without erasing them.
          doCheck = package.build.pythonPackageBuilder.packages.check != [ ];
          pythonImportsCheck = package.build.pythonPackageBuilder.importsCheck;
          pythonRelaxDeps = package.build.pythonPackageBuilder.relaxDeps;
          passthru = sharedBuildAttrs.pkgPassthru package finalAttrs.finalPackage;
          meta = sharedBuildAttrs.pkgMeta package;
        }
        // package.build.extraAttrs
        // lib.optionalAttrs package.build.debug sharedBuildAttrs.debugShellHookAttr
      )
    )
  ) config.forge.packages;
}
