{
  pkgs,
  lib,
  ...
}:

{
  packages.tau-radio = {
    version = "0.2.101-unstable-2026-06-11";
    description = "Web radio - Hijacks audio device using CLAP and Ogg/Opus.";
    homePage = "https://github.com/tau-org/tau-radio";
    mainProgram = "tau-radio";
    license = lib.licenses.eupl12;

    source = {
      git = "github:tau-org/tau-radio/ea9bee2e3cbaa31699db5e7c6ea5d30baa9e23d4";
      hash = "sha256-ddF0N9SJWw5PSbGL05ZUDjjzJRfmvj4gQ0tyw0YCr2k=";
    };

    build.rustPackageBuilder = {
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

    build.extraAttrs = {
      # fatal error: 'opus.h' file not found
      env.NIX_CFLAGS_COMPILE = "-I${pkgs.libopus.dev}/include/opus";
    };

    test.script = ''
      tau-radio --version
    '';
  };
}
