{
  flake-parts-lib,
  lib,
  ...
}:

{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      pkgs,
      sharedBuildAttrs,
      ...
    }@systemArgs:
    {
      packages = lib.mapAttrs (
        packageName: package:
        lib.mkIf package.config.build.pnpmPackageBuilder.enable (
          let
            builderCfg = package.config.build.pnpmPackageBuilder;
            src = sharedBuildAttrs.pkgSource package.config;

            pnpmDeps = pkgs.fetchPnpmDeps (
              {
                inherit (package.config) pname version;
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
              inherit (package.config) pname version;
              inherit src pnpmDeps;
              patches = package.config.source.patches or [ ];

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

              passthru = sharedBuildAttrs.pkgPassthru package.config finalAttrs.finalPackage;
              meta = sharedBuildAttrs.pkgMeta package.config;
            }
            // lib.optionalAttrs (builderCfg.sourceRoot != null) {
              inherit (builderCfg) sourceRoot;
            }
            // package.config.build.extraAttrs
            // lib.optionalAttrs package.config.build.debug sharedBuildAttrs.debugShellHookAttr
          )
        )
      ) systemArgs.config.evals.packages;
    }
  );
}
