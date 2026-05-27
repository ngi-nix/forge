{
  config,
  lib,
  pkgs,
  sharedBuildAttrs,
  ...
}:
{
  packages = lib.mapAttrs (
    packageName: package:
    lib.mkIf package.build.goPackageBuilder.enable (
      pkgs.buildGoModule (
        finalAttrs:
        {
          inherit (package) pname version;
          inherit (package.build.goPackageBuilder)
            vendorHash
            modRoot
            subPackages
            ldflags
            tags
            proxyVendor
            ;
          src = sharedBuildAttrs.pkgSource package;
          patches = package.source.patches;
          nativeBuildInputs = package.build.goPackageBuilder.packages.build;
          buildInputs = package.build.goPackageBuilder.packages.run;
          nativeCheckInputs = package.build.goPackageBuilder.packages.check;
          passthru = sharedBuildAttrs.pkgPassthru package finalAttrs.finalPackage;
          meta = sharedBuildAttrs.pkgMeta package;
        }
        // package.build.extraAttrs
        // lib.optionalAttrs package.build.debug sharedBuildAttrs.debugShellHookAttr
      )
    )
  ) config.forge.packages;
}
