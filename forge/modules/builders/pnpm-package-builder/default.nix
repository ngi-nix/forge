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
    lib.mkIf package.build.pnpmPackageBuilder.enable (
      let
        builderCfg = package.build.pnpmPackageBuilder;
        src = sharedBuildAttrs.pkgSource package;

        pnpmDeps = pkgs.fetchPnpmDeps (
          {
            inherit (package) pname version;
            inherit src;
            inherit (builderCfg) fetcherVersion;
            hash = builderCfg.pnpmDepsHash;
          }
          // lib.optionalAttrs (builderCfg.sourceRoot != null) {
            inherit (builderCfg) sourceRoot;
          }
        );
      in
      pkgs.stdenvNoCC.mkDerivation (
        finalAttrs:
        {
          inherit (package) pname version;
          inherit src pnpmDeps;
          patches = package.source.patches or [ ];

          nativeBuildInputs = [
            pkgs.pnpmConfigHook
            pkgs.pnpm
            pkgs.nodejs
          ]
          ++ builderCfg.packages.build;
          buildInputs = builderCfg.packages.run;
          nativeCheckInputs = builderCfg.packages.check;

          buildPhase = ''
            runHook preBuild
            pnpm run ${builderCfg.buildScript}
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            cp -r ${builderCfg.installDir} $out
            runHook postInstall
          '';

          passthru = sharedBuildAttrs.pkgPassthru package finalAttrs.finalPackage;
          meta = sharedBuildAttrs.pkgMeta package;
        }
        // lib.optionalAttrs (builderCfg.sourceRoot != null) {
          inherit (builderCfg) sourceRoot;
        }
        // package.build.extraAttrs
        // lib.optionalAttrs package.build.debug sharedBuildAttrs.debugShellHookAttr
      )
    )
  ) config.forge.packages;
}
