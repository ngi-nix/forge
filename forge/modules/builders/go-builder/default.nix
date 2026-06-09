{
  config,
  lib,
  pkgs,
  sharedBuildAttrs,
  ...
}:
{
  imports = [ ./options.nix ];
  config = lib.mkIf config.build.goPackageBuilder.enable {
    result.derivation = pkgs.buildGoModule (
      finalAttrs:
      {
        inherit (config) pname version;
        inherit (config.build.goPackageBuilder)
          vendorHash
          modRoot
          subPackages
          ldflags
          tags
          proxyVendor
          ;
        src = sharedBuildAttrs.pkgSource config;
        patches = config.source.patches;
        nativeBuildInputs = config.build.goPackageBuilder.packages.build;
        buildInputs = config.build.goPackageBuilder.packages.run;
        nativeCheckInputs = config.build.goPackageBuilder.packages.check;
        passthru = sharedBuildAttrs.pkgPassthru config finalAttrs.finalPackage;
        meta = sharedBuildAttrs.pkgMeta config;
      }
      // config.build.extraAttrs
      // lib.optionalAttrs config.build.debug sharedBuildAttrs.debugShellHookAttr
    );
  };
}
