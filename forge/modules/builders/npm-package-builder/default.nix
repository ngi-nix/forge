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
    lib.mkIf package.build.npmPackageBuilder.enable (
      pkgs.buildNpmPackage (
        finalAttrs:
        {
          inherit (package) pname version;
          inherit (package.build.npmPackageBuilder)
            npmDepsHash
            npmInstallFlags
            ;
          src = sharedBuildAttrs.pkgSource package;
          patches = package.source.patches or [ ];
          nativeBuildInputs = [ pkgs.nodejs ] ++ package.build.npmPackageBuilder.packages.build;
          buildInputs = package.build.npmPackageBuilder.packages.run;
          nativeCheckInputs = package.build.npmPackageBuilder.packages.check;
          passthru = sharedBuildAttrs.pkgPassthru package finalAttrs.finalPackage;
          meta = sharedBuildAttrs.pkgMeta package;
        }
        // package.build.extraAttrs
        // lib.optionalAttrs package.build.debug sharedBuildAttrs.debugShellHookAttr
      )
    )
  ) config.forge.packages;
}
