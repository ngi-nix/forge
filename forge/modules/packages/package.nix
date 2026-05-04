{
  lib,
  ...
}:
{
  options = {
    # General configuration
    name = lib.mkOption {
      type = lib.types.str;
      default = "my-package";
      description = "Package name.";
      example = "hello";
    };
    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Package description.";
      example = "A program that prints greeting messages";
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "1.0.0";
      description = "Package version.";
      example = "2.12.1";
    };
    homePage = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Package home page URL.";
      example = "https://www.gnu.org/software/hello/hello-2.12.1.tar.gz";
    };
    mainProgram = lib.mkOption {
      type = lib.types.str;
      default = "my-program";
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
      description = "License, or licenses, for the package.";
      example = lib.literalExpression "lib.licenses.gpl3Only";
    };

    # Source configuration
    source = {
      git = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "^.*:.*/.*/.*$");
        default = null;
        description = ''
          Git repository URL with revision.

          Formats:
            - platform:owner/repo/revision
            - git:url?tag=version
            - git:url?rev=hash
        '';
        example = "github:my-user/my-repo/v1.0.0";
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
          Fetch git submodules along with the repository source.

          Only applicable when using `source.git`.
        '';
        example = true;
      };
      patches = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = ''
          List of patch files to apply to the source code.

          Patches are applied in the order specified using the patch command.
        '';
        example = lib.literalExpression "[ ./fix-build.patch ./add-feature.patch ]";
      };
    };

    # Build configuration
    build = {
      # Builder-specific options are defined in separate modular
      # files in forge/modules/builders/ directory.
      # Each builder module defines its own options and configuration logic.

      # Common builder options (available to all builders)
      extraAttrs = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = ''
          Expert option.

          Set extra Nix derivation attributes.
        '';
        example = lib.literalExpression ''
          {
            preConfigure = "export HOME=$(mktemp -d)"
            postInstall = "rm $out/somefile.txt"
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
          nix develop .#<package>
          ```

          and follow instructions.
        '';
      };
    };

    # Test configuration
    test = {
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Additional packages required for running tests.";
        example = lib.literalExpression "[ pkgs.curl pkgs.jq ]";
      };
      script = lib.mkOption {
        type = lib.types.str;
        default = ''
          echo "Test script"
        '';
        description = ''
          Bash script to run package tests.

          The package being tested is available in PATH.
          Run with: nix build .#<package>.test
        '';
        example = lib.literalExpression ''
          '''
          hello | grep "Hello, world"
          '''
        '';
      };
    };

    # Development configuration
    development = {
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Additional packages to include in the development environment.

          All build inputs are automatically included.
        '';
        example = lib.literalExpression "[ pkgs.git pkgs.vim ]";
      };
      shellHook = lib.mkOption {
        type = lib.types.str;
        default = ''
          echo -e "\nWelcome. This environment contains all dependencies required"
          echo "to build $DEVENV_PACKAGE_NAME from source."
          echo
          echo "Grab the source code from $DEVENV_PACKAGE_SOURCE"
          echo "or from the upstream repository and you are all set to start hacking."
        '';
        description = ''
          Bash script to run when entering the development environment.

          Enter with: nix develop .#<package>
        '';
        example = lib.literalExpression ''
          '''
          echo "Welcome to my-package development environment!"
          echo "Run 'make' to build the project"
          '''
        '';
      };
    };

    recipePath = lib.mkOption {
      type = lib.types.str;
      default = "";
      internal = true;
      description = "Path to the recipe.nix file relative to the flake root. Set automatically by the recipe loader.";
    };
  };
}
