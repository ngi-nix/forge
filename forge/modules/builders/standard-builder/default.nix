{
  lib,
  config,
  sharedBuildAttrs,
  ...
}:
{
  imports = [ ./options.nix ];
  config = lib.mkIf config.build.standardBuilder.enable {
    result.derivation = config.build.standardBuilder.stdenv.mkDerivation (
      finalAttrs:
      {
        inherit (config) pname version;
        src = sharedBuildAttrs.pkgSource config;
        patches = config.source.patches;
        nativeBuildInputs = config.build.standardBuilder.packages.build;
        buildInputs = config.build.standardBuilder.packages.run;
        nativeCheckInputs = config.build.standardBuilder.packages.check;
        passthru = sharedBuildAttrs.pkgPassthru config finalAttrs.finalPackage;
        meta = sharedBuildAttrs.pkgMeta config;
      }
      // config.build.extraAttrs
      // lib.optionalAttrs config.build.debug sharedBuildAttrs.debugShellHookAttr
    );
  };
}
