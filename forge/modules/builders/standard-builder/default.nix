{
  lib,
  config,
  sharedBuildAttrs,
  ...
}:
{
  packages = lib.mapAttrs (
    packageName: package:
    # Note that `packages` is a `lazyAttrsOf`,
    # hence `lib.mkIf false` does not remove the attribute key.
    # This does not matter because at least one builder has to be enabled,
    # hence the value always has a definition.
    lib.mkIf package.build.standardBuilder.enable (
      # Remark: a package can use a different `pkgs.stdenv`.
      package.build.standardBuilder.stdenv.mkDerivation (
        finalAttrs:
        {
          inherit (package) pname version;
          src = sharedBuildAttrs.pkgSource package;
          patches = package.source.patches;
          nativeBuildInputs = package.build.standardBuilder.packages.build;
          buildInputs = package.build.standardBuilder.packages.run;
          nativeCheckInputs = package.build.standardBuilder.packages.check;
          passthru = sharedBuildAttrs.pkgPassthru package finalAttrs.finalPackage;
          meta = sharedBuildAttrs.pkgMeta package;
        }
        // package.build.extraAttrs
        // lib.optionalAttrs package.build.debug sharedBuildAttrs.debugShellHookAttr
      )
    )
  ) config.forge.packages;
}
