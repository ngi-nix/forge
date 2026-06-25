{
  config,
  lib,
  pkgs,
  packageBuilderModule,
  ...
}:
let
  builder = config.build.beamMixReleaseBuilder;
  beamPackages = pkgs.beam.packages."erlang_${builder.erlangVersion}".extend (
    finalBeam: previousBeam: {
      elixir = finalBeam."elixir_${builder.elixirVersion}";
    }
  );
in
{
  imports = [
    ./options.nix
    (packageBuilderModule {
      builderName = "beamMixReleaseBuilder";
      # ToDo(compatibility): `mixRelease` is not yet implemented with `lib.extendMkDerivation` as of nixpkgs-26.05
      mkDerivationProvidesFinalAttrs = false;
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
