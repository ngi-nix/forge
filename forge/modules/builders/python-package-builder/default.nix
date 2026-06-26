{
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    (packageBuilderModule {
      name = "pythonPackageBuilder";
      imports = ./options.nix;
      mkDerivation = pkgs.python3Packages.buildPythonPackage;
      attrs = builder: finalAttrs: previousAttrs: {
        format = "pyproject";
        inherit (builder)
          disabledTests
          ;
        inherit (builder.packages)
          build-system
          dependencies
          optional-dependencies
          ;
        pythonImportsCheck = builder.importsCheck;
        pythonRelaxDeps = builder.relaxDeps;
      };
    })
  ];
}
