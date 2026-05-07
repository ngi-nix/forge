{
  specialArgs,
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
        type = lib.types.attrsOf (
          lib.types.submoduleWith {
            modules = [ ./options.nix ];
          }
        );
      };

      config.packages =
        let
          composePkg =
            pkgName: pkg:
            pkgs.callPackage (
              # Derivation start
              { }:
              pkgs.buildNpmPackage (
                finalAttrs:
                {
                  pname = pkg.name;
                  version = pkg.version;
                  src = sharedBuildAttrs.pkgSource pkg;
                  patches = pkg.source.patches or [ ];

                  nativeBuildInputs = [ pkgs.nodejs ] ++ pkg.build.npmPackageBuilder.packages.build;
                  buildInputs = pkg.build.npmPackageBuilder.packages.run;
                  nativeCheckInputs = pkg.build.npmPackageBuilder.packages.check;
                  npmDepsHash = pkg.build.npmPackageBuilder.npmDepsHash;
                  npmInstallFlags = pkg.build.npmPackageBuilder.npmInstallFlags;

                  passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                  meta = sharedBuildAttrs.pkgMeta pkg;
                }
                // pkg.build.extraAttrs
                // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
              )
              # Derivation end
            ) { };

          enabledPkgs = lib.filterAttrs (name: p: p.build.npmPackageBuilder.enable) config.forge.packages;

          npmPackageBuilderPkgs = lib.mapAttrs composePkg enabledPkgs;
        in
        npmPackageBuilderPkgs;
    }
  );
}
