{
  bombon,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.modules.importApply ./builder.nix {
      name = "go";
      imports = go/options.nix;
      mkDerivation = pkgs.buildGoModule;
      passthruVendoredSbom = _: drv: bombon.passthruVendoredSbom.go drv { inherit pkgs; };
      attrs = builder: finalAttrs: previousAttrs: {
        inherit (builder)
          vendorHash
          modRoot
          subPackages
          ldflags
          tags
          proxyVendor
          ;
      };
    })
  ];
}
