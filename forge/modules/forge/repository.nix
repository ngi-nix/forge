{
  inputs,
  flake-parts-lib,
  ...
}:
{
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        options = {
          forge.repository = {
            archiveUrl = lib.mkOption {
              type = lib.types.str;
              default =
                config.forge.repository.homeUrl + "/archive/" + config.forge.repository.commitRef + ".tar.gz";
              defaultText = lib.literalExpression ''config.forge.repository.homeUrl + "/archive/" + inputs.ngi-forge.lib.sourceInfoRef + ".tar.gz"'';
              description = ''
                URL to get an archive of the repository.
              '';
            };
            commitRef = lib.mkOption {
              type = lib.types.str;
              default = inputs.ngi-forge.lib.sourceInfoRef inputs.self;
              defaultText = lib.literalExpression "inputs.ngi-forge.lib.sourceInfoRef inputs.self";
              description = ''
                Reference to the commit of the repository.
              '';
            };
            gitUrl = lib.mkOption {
              type = with lib.types; nullOr str;
              default = config.forge.repository.homeUrl;
              defaultText = lib.literalExpression "config.forge.repository.homeUrl";
              description = ''
                URL to git the repository.
              '';
              example = "https://github.com/ngi-nix/forge";
            };
            homeUrl = lib.mkOption {
              type = lib.types.str;
              default = "https://github.com/" + config.forge.repository.path;
              defaultText = lib.literalExpression ''"https://github.com/" + config.forge.repository.path'';
              description = ''
                URL to the home of the repository.
              '';
              example = "https://github.com/ngi-nix/forge";
            };
            path = lib.mkOption {
              type = lib.types.str;
              description = ''
                Name of the repository.
              '';
              default = "ngi-nix/forge";
            };
            nixUrl = lib.mkOption {
              type = lib.types.str;
              default = "github:" + config.forge.repository.path + "/" + config.forge.repository.commitRef;
              defaultText = lib.literalExpression "";
              description = ''
                URL to fetch the repository using `nix flake`.
              '';
              example = "github:ngi-nix/forge";
            };
            treeUrl = lib.mkOption {
              type = lib.types.str;
              default = config.forge.repository.homeUrl + "/tree/" + config.forge.repository.commitRef;
              defaultText = lib.literalExpression "inputs.ngi-forge.lib.sourceInfoRef inputs.self";
              description = ''
                URL to browse the tree of the repository.
              '';
            };
          };
        };
      }
    );
  };
}
