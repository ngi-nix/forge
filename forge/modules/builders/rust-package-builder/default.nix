{
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    ./options.nix
    (packageBuilderModule {
      builderName = "rustPackageBuilder";
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
