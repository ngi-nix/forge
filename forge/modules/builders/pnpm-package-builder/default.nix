{
  lib,
  config,
  pkgs,
  sharedBuildAttrs,
  ...
}:
{
  imports = [ ./options.nix ];
  config = lib.mkIf config.build.pnpmPackageBuilder.enable {
    result.derivation =
      let
        builderCfg = config.build.pnpmPackageBuilder;
      in
      pkgs.stdenvNoCC.mkDerivation (
        finalAttrs:
        let
          pnpmDeps = pkgs.fetchPnpmDeps ({
            inherit (finalAttrs)
              pname
              src
              version
              sourceRoot
              ;
            inherit (builderCfg) pnpm fetcherVersion;
            hash = builderCfg.pnpmDepsHash;
          });
        in
        {
          inherit (config) pname version;
          inherit pnpmDeps;
          src = sharedBuildAttrs.pkgSource config;
          patches = config.source.patches or [ ];

          nativeBuildInputs = [
            builderCfg.pnpm
            pkgs.pnpmConfigHook
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

          passthru = sharedBuildAttrs.pkgPassthru config finalAttrs.finalPackage;
          meta = sharedBuildAttrs.pkgMeta config;
        }
        // lib.optionalAttrs (builderCfg.sourceRoot != null) {
          inherit (builderCfg) sourceRoot;
        }
        // config.build.extraAttrs
        // lib.optionalAttrs config.build.debug sharedBuildAttrs.debugShellHookAttr
      );
  };
}
