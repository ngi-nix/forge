{
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    (packageBuilderModule {
      name = "goPackageBuilder";
      imports = ./options.nix;
      mkDerivation = pkgs.buildGoModule;
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
