{
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    ./options.nix
    (packageBuilderModule {
      builderName = "pythonAppBuilder";
      mkDerivation = pkgs.python3Packages.buildPythonApplication;
      attrs = builder: finalAttrs: previousAttrs: {
        format = "pyproject";
        inherit (builder.packages)
          build-system
          dependencies
          optional-dependencies
          ;
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
