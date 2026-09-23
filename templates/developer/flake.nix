{
  description = "NGI Forge developer";

  nixConfig = {
    extra-substituters = [
      "https://ngi-forge.cachix.org"
    ];
    extra-trusted-public-keys = [
      "ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0="
    ];
  };

  inputs = {
    ngi-forge.url = "github:ngi-nix/forge";
  };

  outputs =
    { self, ngi-forge, ... }@inputs:
    ngi-forge.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ ngi-forge.flakeModules.default ];

      # Uncomment this to enable debug attributes of this flake.
      # https://flake.parts/options/flake-parts.html?highlight=debug#opt-debug
      # debug = true;

      perSystem =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          # nix fmt
          formatter = pkgs.nixfmt-tree;

          # Build package from local source with: `nix run .#<package>`
          packages = {
            default = config.packages.pkgs.offen.overrideAttrs (
              finalAttrs: prevAttrs: {
                version = prevAttrs.version + "-dev";

                # Local source directory, filtered to avoid unnecessary rebuilds
                src = lib.fileset.toSource {
                  root = ./.;
                  # Files you want to allow
                  fileset = lib.fileset.unions [
                    (lib.fileset.gitTracked ./.)

                    # Extra files
                    #./LICENSE.md
                    #./README.md

                    # Regex
                    #(lib.fileset.fromSource (lib.sources.sourceByRegex ../. [ "^src-.*" ]))
                  ];
                };

                # build-time dependencies
                nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [
                ];

                # run-time dependencies
                buildInputs = prevAttrs.buildInputs or [ ] ++ [
                ];

                # build-time test dependencies
                nativeCheckInputs = prevAttrs.nativeCheckInputs or [ ] ++ [
                ];

                # run-time test dependencies
                checkInputs = prevAttrs.checkInputs or [ ] ++ [
                ];
              }
            );
          };

          # Enter the development shell with: `nix develop`
          devShells.default = pkgs.mkShell {
            # Install build dependencies of a Forge package.
            # NOTE: this doesn't include package itself
            inputsFrom = [
              config.packages.pkgs.offen
            ];

            # Install additional packages
            packages = [
              # pkgs.jq
            ];
          };
        };
    };
}
