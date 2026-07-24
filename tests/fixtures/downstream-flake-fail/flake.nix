{
  description = "A downstream flake that does NOT allowlist the dummy insecure package";

  inputs.ngi-forge.url = "PATH_TO_FORGE";

  outputs =
    inputs@{ ngi-forge, ... }:
    ngi-forge.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ ngi-forge.flakeModules.default ];
      perSystem = { config, pkgs, ... }: {
        forge.repositoryUrl = "foo";
        # We define a dummy package using forge's internal pkgs to verify it rejects insecure packages by default
        packages.dummy = pkgs.hello.overrideAttrs (old: {
          name = "dummy-insecure-pkg-1.0";
          meta = (old.meta or { }) // {
            knownVulnerabilities = [ "test vulnerability" ];
          };
        });
      };
    };
}
