{
  bombon,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.modules.importApply ./builder.nix {
      name = "rust";
      imports = rust/options.nix;
      mkDerivation = pkgs.rustPlatform.buildRustPackage;
      passthruVendoredSbom = _: drv: bombon.passthruVendoredSbom.rust drv { inherit pkgs; };
      attrs = builder: finalAttrs: previousAttrs: {
        inherit (builder)
          cargoHash
          cargoBuildFlags
          ;
      };
    })
  ];

}
