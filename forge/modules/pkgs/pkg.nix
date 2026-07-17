{
  lib,
  name,
  specialArgs,
  ...
}:
{
  imports = [
    ../builders/standard-builder
    ../builders/go-builder
    ../builders/npm-package-builder
    ../builders/pnpm-package-builder
    ../builders/python-app-builder
    ../builders/python-package-builder
    ../builders/rust-package-builder
    ../recipe-metadata.nix
  ];
  config._recipeType = "pkgs";
  options = {
    pname = lib.mkOption {
      type = lib.types.strMatching "^[a-zA-Z0-9-]+$";
      default = name;
      description = "Package name. Only letters, numbers and hyphens are allowed.";
      example = "pkgs.hello";
      readOnly = true;
      internal = true;
    };
    outputName = lib.mkOption {
      type = lib.types.str;
      default = "pkgs.${name}";
      description = "Output name.";
      example = "pkgs.hello";
      readOnly = true;
      internal = true;
    };
    description = lib.mkOption {
      type = lib.types.strMatching "^$|^.{1,119}\\.$";
      default = "";
      description = "Short package description. Maximum 120 characters.";
      example = "A program that prints greeting messages.";
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "1.0.0";
      description = "Package version.";
      example = "2.12.1";
    };
    homePage = lib.mkOption {
      type = lib.types.strMatching "[a-zA-Z][a-zA-Z0-9+\-.]*://[^ \t\n]+";
      default = "";
      description = "Package home page URL.";
      example = "https://www.gnu.org/software/hello/";
    };
    mainProgram = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Name of the main executable program.";
      example = "hello";
    };
    license = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          attrs # lib.licenses.gpl3Only
          str # "gpl3Only"
          (listOf (either attrs str))
        ];
      default = [ ];
      description = ''
        License, or licenses, for the package.

        Can be a single license (e.g. `lib.licenses.gpl3Only`) or a list of licenses.
      '';
      example = lib.literalExpression "[ lib.licenses.mit lib.licenses.asl20 ]";
    };
    maintainers = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = ''
        A list of the maintainers of this package.

        Maintainers needs to be either a Nixpkgs maintainer or a NGI Forge
        maintainer defined in `maintainers/maintainer-list.nix` file.
      '';
      example = lib.literalExpression "with lib.maintainers; [ ngi-nix ]";
    };

    # Source configuration
    source = {
      git = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "^.*:.*/.*/.*$");
        default = null;
        description = ''
          Git repository URL with revision.

          Supported forges:
            - `github:owner/repo/revision`
            - `gitlab:owner/repo/revision`
            - `codeberg:owner/repo/revision`
            - `forgejo:domain/owner/repo/revision`
            - `gitea:domain/owner/repo/revision`
            - `git:https://url?rev=hash`
            - `git:https://url?tag=version`
        '';
        example = lib.literalExpression ''
          # GitHub
          "github:my-user/my-repo/v1.0.0"

          # Codeberg
          "codeberg:my-user/my-repo/v1.0.0"

          # Self-hosted Forgejo instance
          "forgejo:git.example.com/my-user/my-repo/v1.0.0"

          # Arbitrary git URL
          "git:https://git.example.com/my-repo?tag=v1.0.0"
        '';
      };
      url = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "^.*://.*");
        default = null;
        description = "Source tarball URL.";
        example = "https://downloads.my-project/my-package-1.0.0.tar.gz";
      };
      path = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Relative path to local source code directory.";
        example = lib.literalExpression "./backend/src";
      };
      hash = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Source code hash.

          Use empty string to get the hash during a first build.
        '';
        example = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
      };
      submodules = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Fetch Git submodules along with the repository source.

          Only applicable when using `source.git`.
        '';
        example = true;
      };
      patches = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = ''
          List of patch files to be applied to the source code.

          Patches are applied in the order specified using the patch command.
        '';
        example = lib.literalExpression "[ ./fix-build.patch ./add-feature.patch ]";
      };
    };

    # Build configuration
    build = lib.mkOption {
      description = "Package build options.";
      type = lib.types.submoduleWith {
        inherit specialArgs;
        modules = [
          {
            options = {
              # Builder-specific options are defined in separate modular
              # files in forge/modules/builders/ directory.
              # Each builder module defines its own options and configuration logic.

              # Common builder options (available to all builders)
              extraAttrs = lib.mkOption {
                # `lazyAttrsOf` enables to use `pkgs` inside `extraAttrs`.
                type = lib.types.lazyAttrsOf lib.types.anything;
                default = { };
                description = ''
                  Extra attributes merged into the derivation produced by the selected builder.

                  Use this to pass builder-specific phase hooks (`preConfigure`,
                  `postInstall`, …), environment variables, or any other
                  `stdenv.mkDerivation` attribute not exposed as a dedicated option.
                  Attributes set here take precedence over the builder defaults.

                  Expert option. For more information see the
                  [Nixpkgs manual](https://nixos.org/manual/nixpkgs/unstable/).
                '';
                example = lib.literalExpression ''
                  {
                    # Set HOME for tools that require a writable home directory
                    preConfigure = "export HOME=$(mktemp -d)";

                    # Remove unwanted files from the output
                    postInstall = "rm $out/share/doc/my-package/INSTALL";

                    # Pass extra flags to configure
                    configureFlags = [ "--disable-static" "--enable-shared" ];

                    # Set an environment variable for the build
                    MY_VARIABLE = "value";
                  }
                '';
              };
              debug = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Enable interactive package build environment for debugging.

                  Launch environment:

                  ```
                  mkdir dev && cd dev
                  nix develop .#pkgs.''${package}
                  ```

                  and follow instructions.
                '';
              };
            };
          }
        ];
      };
    };

    # Test configuration
    test = {
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "List of packages available in the test script.";
        example = lib.literalExpression "[ pkgs.curl pkgs.jq ]";
      };
      script = lib.mkOption {
        type = lib.types.str;
        default = ''
          echo "Test script"
        '';
        description = ''
          Script to test the package.
          The package being tested is available in PATH.

          Launch test with:

          ```
          nix build .#pkgs.''${package}.test
          ```
        '';
        example = ''
          hello | grep "Hello, world"
        '';
      };
    };

    # Development configuration
    develop = {
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of packages available in the development environment.

          All build inputs are automatically included.
        '';
        example = lib.literalExpression "[ pkgs.git pkgs.vim ]";
      };
      shellHook = lib.mkOption {
        type = lib.types.str;
        default = ''
          echo -e "\nWelcome. This environment contains all dependencies required"
          echo "to build $ENV_PACKAGE_NAME from source."
          echo
          echo "Grab the source code from $ENV_PACKAGE_SOURCE"
          echo "or from the upstream repository and you are all set to start hacking."
        '';
        description = ''
          Script which is launched when entering the development environment.

          Enter with:

          ```
          nix develop .#pkgs.''${package}.env
          ```
        '';
        example = ''
          echo "Welcome to my-package development environment!"
          echo "Run 'make' to build the project"
        '';
      };
    };

    result = {
      derivation = lib.mkOption {
        type = lib.types.package;
        internal = true;
        description = "Resulting derivation of the package.";
      };
    };
  };
}
