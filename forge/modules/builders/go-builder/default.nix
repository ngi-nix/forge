{
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
          type = lib.types.attrsOf (lib.types.submoduleWith { modules = [ ./options.nix ]; });
        };

        config = {
          packages =
            let
              composePkg =
                pkgName: pkg:
                pkgs.callPackage (
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

              enabledPkgs = lib.filterAttrs (name: p: p.build.goPackageBuilder.enable) config.forge.packages;

              goPackageBuilderPkgs = lib.mapAttrs composePkg enabledPkgs;
            in
            goPackageBuilderPkgs;
        };
      }
    );
  };
}
