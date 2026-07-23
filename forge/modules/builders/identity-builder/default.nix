{
  packageBuilderModule,
  ...
}:
{
  imports = [
    (packageBuilderModule {
      name = "identityBuilder";
      imports = ./options.nix;
      mkDerivation = mk: (mk { }).derivation;
      attrs = builder: finalAttrs: previousAttrs: {
        derivation = builder.derivation;
      };
    })
    (
      {
        config,
        lib,
        ...
      }:
      {
        config =
          let
            builder = config.build.identityBuilder;
            drv = builder.derivation;
          in
          lib.mkIf builder.enable {
            homePage = drv.meta.homepage;
            description = lib.removeSuffix "." drv.meta.description + ".";
            inherit (drv) version;
            inherit (drv.meta)
              license
              ;
          };
      }
    )
  ];
}
