{
  config,
  lib,
  sharedBuildAttrs,
  ...
}:
{
  packages = lib.mapAttrs (
    packageName: package:
    lib.mkIf package.build.ocamlBuilder.enable (
      package.build.ocamlBuilder.packages.scope.buildDunePackage (
        finalAttrs:
        {
          inherit (package) pname version;

          __structuredAttrs = true;
          env.DUNE_CACHE = "disabled";

          src = sharedBuildAttrs.pkgSource package;
          patches = package.source.patches;
          nativeBuildInputs = package.build.ocamlBuilder.packages.build;
          buildInputs = package.build.ocamlBuilder.packages.run;
          propagatedBuildInputs = package.build.ocamlBuilder.packages.dep;
          checkInputs = package.build.ocamlBuilder.packages.check;
          passthru = sharedBuildAttrs.pkgPassthru package finalAttrs.finalPackage;
          meta = sharedBuildAttrs.pkgMeta package;
        }
        // lib.optionalAttrs (package.build.ocamlBuilder.packages.require != null) {
          minimalOCamlVersion = package.build.ocamlBuilder.packages.require;
        }
        // package.build.extraAttrs
        // lib.optionalAttrs package.build.debug sharedBuildAttrs.debugShellHookAttr
      )
    )
  ) config.forge.packages;
}
