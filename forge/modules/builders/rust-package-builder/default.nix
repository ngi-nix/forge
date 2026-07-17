{
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    (packageBuilderModule {
      name = "rustPackageBuilder";
      imports = ./options.nix;
      mkDerivation = pkgs.rustPlatform.buildRustPackage;
      attrs = builder: finalAttrs: previousAttrs: {
        inherit (builder)
          cargoHash
          cargoBuildFlags
          ;
      };
    })
  ];

}
