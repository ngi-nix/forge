{
  flake-parts-lib,
  lib,
  ...
}:

let
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
in
{
  options.perSystem = mkPerSystemOption (
    {
      config,
      pkgs,
      sharedBuildAttrs,
      ...
    }:
    {
      options.forge.packages = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submoduleWith { modules = [ ./options.nix ]; });
      };

      config.packages =
        let
          composePkg =
            pkgName: pkg:
            pkgs.callPackage (
              # Derivation start
              { }:
              let
                builderCfg = pkg.build.pnpmPackageBuilder;
                src = sharedBuildAttrs.pkgSource pkg;

                pnpmDeps = pkgs.fetchPnpmDeps (
                  {
                    pname = pkg.name;
                    version = pkg.version;
                    inherit src;
                    fetcherVersion = builderCfg.fetcherVersion;
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
                  pname = pkg.name;
                  version = pkg.version;
                  inherit src pnpmDeps;
                  patches = pkg.source.patches or [ ];

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

                  passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                  meta = sharedBuildAttrs.pkgMeta pkg;
                }
                // lib.optionalAttrs (builderCfg.sourceRoot != null) {
                  inherit (builderCfg) sourceRoot;
                }
                // pkg.build.extraAttrs
                // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
              )
              # Derivation end
            ) { };

          enabledPkgs = lib.filterAttrs (name: p: p.build.pnpmPackageBuilder.enable) config.forge.packages;

          pnpmPackageBuilderPkgs = lib.mapAttrs composePkg enabledPkgs;
        in
        pnpmPackageBuilderPkgs;
    }
  );
}
