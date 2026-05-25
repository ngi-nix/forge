{
  config,
  lib,
  self-inputs,
  forge-inputs,
  ...
}:
{
  options = {
    archiveUrl = lib.mkOption {
      type = lib.types.str;
      default = config.homeUrl + "/archive/" + config.commitRef + ".tar.gz";
      defaultText = lib.literalExpression ''config.homeUrl + "/archive/" + forge-inputs.self.lib.sourceInfoRef + ".tar.gz"'';
      description = ''
        URL to get an archive of the repository.
      '';
    };
    commitRef = lib.mkOption {
      type = lib.types.str;
      default = forge-inputs.self.lib.sourceInfoRef self-inputs.self;
      defaultText = lib.literalExpression "forge-inputs.self.lib.sourceInfoRef inputs.self";
      description = ''
        Reference to the commit of the repository.
      '';
    };
    gitUrl = lib.mkOption {
      type = with lib.types; nullOr str;
      default = config.homeUrl;
      defaultText = lib.literalExpression "config.homeUrl";
      description = ''
        URL to git the repository.
      '';
      example = "https://github.com/ngi-nix/forge";
    };
    homeUrl = lib.mkOption {
      type = lib.types.str;
      defaultText = lib.literalExpression ''"https://github.com/" + config.path'';
      description = ''
        URL to the home of the repository.
      '';
      example = "https://github.com/my-user/my-repo";
    };
    path = lib.mkOption {
      type = lib.types.str;
      description = ''
        Name of the repository.
      '';
      example = "ngi-nix/forge";
    };
    nixUrl = lib.mkOption {
      type = lib.types.str;
      default = "github:" + config.path + "/" + config.commitRef;
      defaultText = lib.literalExpression ''"github:" + config.path + "/" + config.commitRef'';
      description = ''
        URL to fetch the repository using `nix flake`.
      '';
      example = "github:ngi-nix/forge";
    };
    nixUrlLatest = lib.mkOption {
      type = lib.types.str;
      default = "github:" + config.path + "/" + "main";
      defaultText = lib.literalExpression ''"github:" + config.path + "/" + "main"'';
      description = ''
        URL to fetch the latest revision of the repository using `nix flake`.
      '';
      example = "github:ngi-nix/forge";
    };
    treeUrl = lib.mkOption {
      type = lib.types.str;
      default = config.homeUrl + "/tree/" + config.commitRef;
      defaultText = lib.literalExpression ''config.homeUrl + "/tree/" + config.commitRef'';
      description = ''
        URL to browse the tree of the repository.
      '';
    };
  };
}
