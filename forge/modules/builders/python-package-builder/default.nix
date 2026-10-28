{
  pkgs,
  lib,
  packageBuilderModule,
  ...
}:
{
  imports = [
    (packageBuilderModule {
      name = "pythonPackageBuilder";
      imports = ./options.nix;
      mkDerivation = pkgs.python3Packages.buildPythonPackage;
      mkDerivationProvidesFinalAttrs = false;
      attrs = builder: finalAttrs: previousAttrs: {
        format = "pyproject";
        inherit (builder)
          disabledTests
          ;
        build-system =
          if lib.isFunction builder.packages.build-system then
            builder.packages.build-system pkgs
          else
            builder.packages.build-system;
        dependencies =
          if lib.isFunction builder.packages.dependencies then
            builder.packages.dependencies pkgs
          else
            builder.packages.dependencies;
        optional-dependencies =
          if lib.isFunction builder.packages.optional-dependencies then
            builder.packages.optional-dependencies pkgs
          else
            builder.packages.optional-dependencies;
        pythonImportsCheck = builder.importsCheck;
        pythonRelaxDeps = builder.relaxDeps;
      };
    })
  ];
}
