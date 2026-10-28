{
  config,
  pkgs,
  lib,
  packageBuilderModule,
  ...
}:

{
  imports = [
    (packageBuilderModule {
      name = "ocamlBuilder";
      imports = ./options.nix;
      mkDerivation = config.build.ocamlBuilder.buildDunePackage;
      mkDerivationProvidesFinalAttrs = false;
      attrs =
        builder: finalAttrs: previousAttrs:
        let
          dependencies =
            if lib.isFunction builder.packages.dependencies then
              builder.packages.dependencies pkgs
            else
              builder.packages.dependencies;
        in
        {
          propagatedBuildInputs = previousAttrs.propagatedBuildInputs or [ ] ++ dependencies;

          env = (previousAttrs.env or { }) // {
            DUNE_CACHE = "disabled";
          };
        }
        // lib.optionalAttrs (builder.minimalVersion != null) {
          minimalOCamlVersion = builder.minimalVersion;
        };
    })
  ];
}
