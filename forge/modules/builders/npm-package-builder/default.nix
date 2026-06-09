{
  lib,
  config,
  pkgs,
  sharedBuildAttrs,
  ...
}:
{
  imports = [ ./options.nix ];
  config = lib.mkIf config.build.npmPackageBuilder.enable {
    result.derivation = pkgs.buildNpmPackage (
      finalAttrs:
      {
        inherit (config) pname version;
        inherit (config.build.npmPackageBuilder)
          npmDepsHash
          npmInstallFlags
          ;
        src = sharedBuildAttrs.pkgSource config;
        patches = config.source.patches or [ ];
        nativeBuildInputs = [ pkgs.nodejs ] ++ config.build.npmPackageBuilder.packages.build;
        buildInputs = config.build.npmPackageBuilder.packages.run;
        nativeCheckInputs = config.build.npmPackageBuilder.packages.check;
        passthru = sharedBuildAttrs.pkgPassthru config finalAttrs.finalPackage;
        meta = sharedBuildAttrs.pkgMeta config;
      }
      // config.build.extraAttrs
      // lib.optionalAttrs config.build.debug sharedBuildAttrs.debugShellHookAttr
    );
  };
}
