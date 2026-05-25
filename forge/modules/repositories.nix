{
  lib,
  forge-inputs,
  self-inputs,
  ...
}:
{
  options.forge = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        (
          { specialArgs, ... }@forgeArgs:
          {
            options.repository = lib.mkOption {
              type = lib.types.submoduleWith {
                inherit specialArgs;
                modules = [ repositories/repository.nix ];
              };
              internal = true;
              readOnly = true;
              default = forgeArgs.config.repositories.${lib.unsafeDiscardStringContext self-inputs.self};
              defaultText = "forgeArgs.config.repositories.\${lib.unsafeDiscardStringContext self-inputs.self.outPath}";
              description = ''
                Metadata of the final repository (`inputs.self`)
                Used in the Web interface to display nix commands.
              '';
            };

            options.repositories = lib.mkOption {
              default = { };
              description = ''
                Repositories' metadata indexed by their Nix store path.
                Used to build link to recipe files (`{apps,packages}.''${name}.recipeUrls`).
              '';
              type = lib.types.attrsOf (
                lib.types.submoduleWith {
                  inherit specialArgs;
                  modules = [
                    repositories/repository.nix
                  ];
                }
              );
            };
            config.repositories = {
              ${lib.unsafeDiscardStringContext forge-inputs.self.outPath} =
                { config, ... }:
                {
                  archiveUrl = config.homeUrl + "/archive/" + config.commitRef + ".tar.gz";
                  commitRef = forge-inputs.self.lib.sourceInfoRef forge-inputs.self;
                  gitUrl = config.homeUrl;
                  homeUrl = "https://github.com/" + config.path;
                  path = "ngi-nix/forge";
                  nixUrl = "github:" + config.path + "/" + config.commitRef;
                  nixUrlLatest = "github:" + config.path + "/" + "master";
                  treeUrl = config.homeUrl + "/tree/" + config.commitRef;
                };
            };
          }
        )
      ];
    };
  };
}
