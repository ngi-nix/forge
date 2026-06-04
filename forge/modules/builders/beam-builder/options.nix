{
  lib,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      BEAM (Erlang, Elixir & LFE) builder for applications.

      Uses `mixRelease` from Nixpkgs, which builds BEAM modules using the
      mix toolchain.

      For more information, see the
      [Nixpkgs BEAM documentation](https://nixos.org/manual/nixpkgs/unstable/#sec-beam)
    '';
    erlangVersion = lib.mkOption {
      type = lib.types.enum [
        "26"
        "27"
        "28"
        "29"
      ];
      default = "29";
      description = ''
        The version of Erlang to use for the build.
      '';
    };
    elixirVersion = lib.mkOption {
      type = lib.types.enum [
        "1_15"
        "1_16"
        "1_17"
        "1_18"
        "1_19"
        "1_20"
      ];
      default = "1_20";
      description = ''
        The version of Elixir to use for the build.
      '';
    };
    mixEnv = lib.mkOption {
      type = lib.types.str;
      default = "prod";
      example = "dev";
      description = "
          If not empty, name of the mix environment to use.
          See <https://mix.hexdocs.pm/1.20.1/Mix.html#module-environments>.
          If empty all mix dependencies are fetched.

          Mapped to `MIX_ENV` envvar.
        ";
    };
    mixFodDepsHash = lib.mkOption {
      type = with lib.types; nullOr str;
      default = "";
      description = ''
        If not null, hash of the fixed-output derivation providing Mix dependencies.
        If null, fixed-output derivation is not used.

        Mapped to the `hash` given to `fetchMixDeps` used to build `mixRelease`'s `mixFodDeps`.
      '';
      example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    mixReleaseName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "
          If not empty, name of the release to build.
          See <https://mix.hexdocs.pm/1.20.1/Mix.Tasks.Release.html>.

          Mapped to `mixRelease`'s `mixReleaseName`.
        ";
    };
    mixTarget = lib.mkOption {
      type = lib.types.str;
      default = "host";
      description = "
          See <https://mix.hexdocs.pm/1.20.1/Mix.html#module-targets>.

          Mapped to `MIX_TARGET` envvar.
        ";
    };
  };
}
