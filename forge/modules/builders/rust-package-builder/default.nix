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
        type = lib.types.listOf (lib.types.submodule ./options.nix);
      };

      config.packages =
        let
          cfg = config.forge;

          composePkg = pkg: {
            name = pkg.name;
            value = pkgs.callPackage (
              # Derivation start
              { }:
              pkgs.rustPlatform.buildRustPackage (
                finalAttrs:
                {
                  pname = pkg.name;
                  version = pkg.version;
                  src = sharedBuildAttrs.pkgSource pkg;
                  patches = pkg.source.patches or [ ];

                  nativeBuildInputs = pkg.build.rustPackageBuilder.packages.build;
                  buildInputs = pkg.build.rustPackageBuilder.packages.run;
                  nativeCheckInputs = pkg.build.rustPackageBuilder.packages.check;

                  cargoHash = pkg.build.rustPackageBuilder.cargoHash;
                  cargoBuildFlags = pkg.build.rustPackageBuilder.cargoBuildFlags;

                  passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                  meta = sharedBuildAttrs.pkgMeta pkg;
                }
                // pkg.build.extraAttrs
                // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
              )
              # Derivation end
            ) { };
          };

          enabledPkgs = lib.filter (p: p.build.rustPackageBuilder.enable) cfg.packages;

          rustPackageBuilderPkgs = lib.listToAttrs (map composePkg enabledPkgs);
        in
        rustPackageBuilderPkgs;
    }
  );
}
