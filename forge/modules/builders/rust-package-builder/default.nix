{
  lib,
  config,
  pkgs,
  sharedBuildAttrs,
  ...
}:
{
  imports = [ ./options.nix ];
  config = lib.mkIf config.build.rustPackageBuilder.enable {
    result.derivation = pkgs.rustPlatform.buildRustPackage (
      finalAttrs:
      {
        inherit (config) pname version;
        inherit (config.build.rustPackageBuilder)
          cargoHash
          cargoBuildFlags
          ;

        src = sharedBuildAttrs.pkgSource config;
        patches = config.source.patches or [ ];

        nativeBuildInputs = config.build.rustPackageBuilder.packages.build;
        buildInputs = config.build.rustPackageBuilder.packages.run;
        nativeCheckInputs = config.build.rustPackageBuilder.packages.check;

        passthru = sharedBuildAttrs.pkgPassthru config finalAttrs.finalPackage;
        meta = sharedBuildAttrs.pkgMeta config;
      }
      // config.build.extraAttrs
      // lib.optionalAttrs config.build.debug sharedBuildAttrs.debugShellHookAttr
    );
  };
}
