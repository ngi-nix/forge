{
  pkgs,
  lib,
  packageBuilderModule,
  ...
}:
{
  imports = [
    (packageBuilderModule {
      name = "pythonAppBuilder";
      imports = ./options.nix;
      mkDerivation = pkgs.python3Packages.buildPythonApplication;
      mkDerivationProvidesFinalAttrs = false;
      attrs = builder: finalAttrs: previousAttrs: {
        format = "pyproject";
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
        inherit (builder)
          disabledTests
          ;
        # Warning(consistency): such renames are not done elsewhere,
        # eg. in `pkgs.${package}.build.npmPackageBuilder.npmDepsHash`
        pythonImportsCheck = builder.importsCheck;
        pythonRelaxDeps = builder.relaxDeps;
      };
    })
  ];
}
