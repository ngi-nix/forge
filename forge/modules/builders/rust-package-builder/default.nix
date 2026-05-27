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
    lib.mkIf package.build.rustPackageBuilder.enable (
      pkgs.rustPlatform.buildRustPackage (
        finalAttrs:
        {
          inherit (package) pname version;
          inherit (package.build.rustPackageBuilder)
            cargoHash
            cargoBuildFlags
            ;

          src = sharedBuildAttrs.pkgSource package;
          patches = package.source.patches or [ ];

          nativeBuildInputs = package.build.rustPackageBuilder.packages.build;
          buildInputs = package.build.rustPackageBuilder.packages.run;
          nativeCheckInputs = package.build.rustPackageBuilder.packages.check;

          passthru = sharedBuildAttrs.pkgPassthru package finalAttrs.finalPackage;
          meta = sharedBuildAttrs.pkgMeta package;
        }
        // package.build.extraAttrs
        // lib.optionalAttrs package.build.debug sharedBuildAttrs.debugShellHookAttr
      )
    )
  ) config.forge.packages;
}
