{
  config,
  lib,
  pkgs,
  ...
}:
let
  builder = config.build.builders.beam;
  beamPackages = pkgs.beam.packages."erlang_${builder.erlangVersion}".overrideScope (
    finalBeam: previousBeam: {
      elixir = finalBeam."elixir_${builder.elixirVersion}";
    }
  );
in
{
  imports = [
    (lib.modules.importApply ./builder.nix {
      name = "beam";
      imports = beam/options.nix;
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
