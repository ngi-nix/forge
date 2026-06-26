{
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    (packageBuilderModule {
      name = "npmPackageBuilder";
      imports = ./options.nix;
      mkDerivation = pkgs.buildNpmPackage;
      attrs = builder: finalAttrs: previousAttrs: {
        nativeBuildInputs = previousAttrs.nativeBuildInputs or [ ] ++ [
          pkgs.nodejs
        ];
        inherit (builder)
          npmDepsHash
          npmInstallFlags
          ;
      };
    })
  ];
}
