{
  config,
  lib,
  pkgs,
  packageBuilderModule,
  ...
}:

{
  imports = [
    (packageBuilderModule {
      name = "ocamlBuilder";
      imports = ./options.nix;
      mkDerivation = (config.build.ocamlBuilder.ocamlPackages pkgs).buildDunePackage;
      attrs =
        builder: finalAttrs: previousAttrs:
        {
          propagatedBuildInputs =
            (previousAttrs.propagatedBuildInputs or [ ]) ++ builder.packages.dependencies;

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
