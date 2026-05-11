{
  app,
  config,
  pkgs,
  lib,
  ...
}:
# containerConfig is the container module's config, closed over via args
let
  containerConfig = config;
in
({ pkgs, lib, ... }: {
  project.name = app.name;

  services.${app.name}.image = {
    contents =
      lib.optionals (containerConfig.packages != [ ]) [
        (pkgs.buildEnv {
          name = "runtime-bins";
          paths = containerConfig.packages;
          pathsToLink = [ "/bin" ];
        })
      ];

    rawConfig = containerConfig.extraConfig // {
      Env =
        let
          envAttrsToList = attrs: lib.mapAttrsToList (n: v: "${n}=${v}") attrs;

          appEnv = lib.concatMapAttrs (_: value: value.environment) app.services.components;

          containerEnv = lib.listToAttrs (
            map (
              envPair:
              let
                parts = lib.splitString "=" envPair;
              in
              {
                name = lib.head parts;
                value = lib.concatStringsSep "=" (lib.tail parts);
              }
            ) (containerConfig.extraConfig.Env or [ ])
          );

          envList = appEnv // containerEnv;
        in
        envAttrsToList envList;
    };
  };
})
