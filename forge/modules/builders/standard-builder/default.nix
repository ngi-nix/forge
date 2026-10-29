{
  config,
  packageBuilderModule,
  ...
}:
{
  imports = [
    (packageBuilderModule {
      name = "standardBuilder";
      imports = ./options.nix;
      mkDerivation = config.build.standardBuilder.stdenv.mkDerivation;
      attrs =
        builder: finalAttrs: previousAttrs:
        { };
    })
  ];
}
