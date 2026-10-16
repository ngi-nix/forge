{
  config,
  lib,
  pkgs,
  packageBuilderModule,
  ...
}:
let
  builder = config.build.beamMixReleaseBuilder;
  beamPackages = pkgs.beam.packages."erlang_${builder.erlangVersion}".overrideScope (
    finalBeam: previousBeam: {
      elixir = finalBeam."elixir_${builder.elixirVersion}";
    }
  );
in
{
  imports = [
    (packageBuilderModule {
      name = "beamMixReleaseBuilder";
      imports = ./options.nix;
      mkDerivation = beamPackages.mixRelease;
      attrs =
        builder: finalAttrs: previousAttrs:
        (
          previousAttrs
          // {
            inherit (builder) mixEnv mixReleaseName mixTarget;
          }
          // lib.optionalAttrs (builder.mixFodDepsHash != null) {
            mixFodDeps =
              beamPackages.fetchMixDeps {
                pname = "mix-deps-${finalAttrs.pname}";
                inherit (finalAttrs) version src;
                hash = builder.mixFodDepsHash;
              }
              // finalAttrs.env;
          }
        );
    })
  ];
}
