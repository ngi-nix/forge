{
  inputs,
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
    perSystem = mkPerSystemOption (
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

        config = {
          packages =
            let
              cfg = config.forge.packages;

              goPackageBuilderPkgs = lib.listToAttrs (
                map (pkg: {
                  name = pkg.name;
                  value = pkgs.callPackage (
                    # Derivation start
                    { }:
                    pkgs.buildGoModule (
                      finalAttrs:
                      {
                        pname = pkg.name;
                        version = pkg.version;
                        src = sharedBuildAttrs.pkgSource pkg;
                        patches = pkg.source.patches;
                        vendorHash = pkg.build.goPackageBuilder.vendorHash;
                        modRoot = pkg.build.goPackageBuilder.modRoot;
                        subPackages = pkg.build.goPackageBuilder.subPackages;
                        ldflags = pkg.build.goPackageBuilder.ldflags;
                        tags = pkg.build.goPackageBuilder.tags;
                        proxyVendor = pkg.build.goPackageBuilder.proxyVendor;
                        nativeBuildInputs = pkg.build.goPackageBuilder.packages.build;
                        buildInputs = pkg.build.goPackageBuilder.packages.run;
                        nativeCheckInputs = pkg.build.goPackageBuilder.packages.check;
                        passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                        meta = sharedBuildAttrs.pkgMeta pkg;
                      }
                      // pkg.build.extraAttrs
                      // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
                    )
                    # Derivation end
                  ) { };
                }) (lib.filter (p: p.build.goPackageBuilder.enable == true) cfg)
              );
            in
            goPackageBuilderPkgs;
        };
      }
    );
  };
}
