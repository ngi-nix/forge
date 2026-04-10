{
  inputs,
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
    perSystem = mkPerSystemOption (
      { config, pkgs, ... }:
      let
        # Define shared build attributes here so they can be passed via _module.args
        sharedBuildAttrs = {
          pkgSource =
            let
              fetchers = {
                path = pkg: pkg.source.path;

                git =
                  let
                    forges = {
                      # forge = fetchFunction
                      codeberg = pkgs.fetchFromCodeberg;
                      forgejo = pkgs.fetchFromForgejo;
                      gitea = pkgs.fetchFromGitea;
                      github = pkgs.fetchFromGitHub;
                      gitlab = pkgs.fetchFromGitLab;
                    };

                    gitSchemas = lib.fix (self: {
                      "3" = [
                        "owner"
                        "repo"
                        "rev"
                      ];

                      "4" = [ "domain" ] ++ self."3";
                    });
                  in
                  pkg:
                  let
                    # Expected formats:
                    # - "forge:owner/repo/rev"
                    # - "forge:domain/owner/repo/rev"
                    parts = lib.splitString ":" pkg.source.git;
                    forge = lib.elemAt parts 0;
                    rest = lib.concatStringsSep ":" (lib.tail parts);
                  in
                  if forge == "git" then
                    let
                      # Split "https://host/path?key=value" into url and query
                      urlParts = lib.splitString "?" rest;
                      url = lib.elemAt urlParts 0;
                      queryAttrs =
                        let
                          # Parse key-value pairs into an attrset:
                          #   "key1=value1&key2=value2" -> { key1 = value; key2 = value2; }
                          parseQuery =
                            query:
                            lib.listToAttrs (
                              map (
                                param:
                                let
                                  kv = lib.splitString "=" param;
                                in
                                lib.nameValuePair (lib.elemAt kv 0) (lib.elemAt kv 1)
                              ) (lib.splitString "&" query)
                            );
                        in
                        if lib.length urlParts > 1 then parseQuery (lib.elemAt urlParts 1) else { };
                    in
                    pkgs.fetchgit (
                      lib.recursiveUpdate queryAttrs {
                        inherit url;
                        hash = pkg.source.hash;
                      }
                    )
                  else
                    let
                      pathParts = lib.splitString "/" rest;
                      schema = gitSchemas.${toString (lib.length pathParts)};

                      # assign each source attribute to its appropriate path part
                      sourceAttrs = lib.listToAttrs (lib.zipListsWith lib.nameValuePair schema pathParts);
                    in
                    forges.${forge} (
                      lib.recursiveUpdate sourceAttrs {
                        hash = pkg.source.hash;
                      }
                    );

                url =
                  pkg:
                  pkgs.fetchurl {
                    url = pkg.source.url;
                    hash = pkg.source.hash;
                  };
              };

              # Determine which source type is used
              sourceType =
                pkg:
                if pkg.source.path != null then
                  "path"
                else if pkg.source.git != null then
                  "git"
                else
                  "url";
            in
            pkg: fetchers.${sourceType pkg} pkg;

          pkgPassthru = pkg: finalPkg: {
            test = pkgs.testers.runCommand {
              name = "${pkg.name}-test";
              buildInputs = [ finalPkg ] ++ pkg.test.packages;
              script = pkg.test.script + "\ntouch $out";
            };
            devenv = pkgs.mkShell {
              env.DEVENV_PACKAGE_NAME = "${pkg.name}";
              env.DEVENV_PACKAGE_SOURCE = "${finalPkg.src}";
              inputsFrom = [
                finalPkg
              ];
              packages = pkg.development.packages;
              shellHook = pkg.development.shellHook;
            };
          };

          pkgMeta = pkg: {
            description = pkg.description;
            homepage = pkg.homePage;
            mainProgram = pkg.mainProgram;
            license = pkg.license;
          };

          debugShellHookAttr = {
            shellHook = "source ${inputs.nix-utils}/nix-develop-interactive.bash";
          };
        };
      in
      {
        options = {
          # No options needed
        };

        config = {
          # Pass shared build attributes to other modules via _module.args
          _module.args.sharedBuildAttrs = sharedBuildAttrs;
        };
      }
    );
  };
}
