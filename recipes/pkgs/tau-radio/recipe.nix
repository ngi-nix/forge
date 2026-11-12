{
  pkgs,
  lib,
  ...
}:

{
  pkgs.tau-radio = {
    version = "0.2.101-unstable-2026-08-23";
    description = "Web radio - Hijacks audio device using CLAP and Ogg/Opus.";
    homePage = "https://github.com/tau-org/tau-radio";
    mainProgram = "tau-radio";
    license = lib.licenses.eupl12;

    source = {
      git = "github:tau-org/tau-radio/f9980c52fa4dc1739c2f0c56703f2a9cf960f385";
      hash = "sha256-/Q0/nQ46LLoUsMMnsZWc+HJmdtiTpwbtDkVPz2dig4o=";
    };

    build.builders.rust = {
      enable = true;
      packages = {
        build = with pkgs; [
          pkg-config
          rustPlatform.bindgenHook
        ];
        run =
          with pkgs;
          [
            libogg
            libopus
            libopusenc
            libshout
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            alsa-lib
            jack2
          ];
      };
      cargoHash = "sha256-X1uHKYgt9ddvr/cBDW9HaHawG5uv2sU416jyL/XTPF4=";
    };

    build.phases.configure = {
      # fatal error: 'opus.h' file not found
      # Because `pkg-config`'s configuration
      # from `pkgs.libopus.dev` in `nativeBuildInputs` is not considered
      # by the `bingen` wrapper.
      script.pre = ''
        BINDGEN_EXTRA_CLANG_ARGS+=" $(pkg-config opus --cflags)"
      '';
    };

    test.script = ''
      tau-radio --version
    '';
  };
}
