{
  app,

  config,
  pkgs,
  lib,
  ...
}:
{
  binName = "${app.name}-service";

  container = {
    copyToRoot = pkgs.buildEnv {
      name = "runtime-bins";
      paths = config.packages;
      pathsToLink = [ "/bin" ];
    };

    imageConfig = config.imageConfig // {
      Env =
        let
          # { K = "V"; } -> [ "K=V" ]
          envAttrsToList = attrs: lib.mapAttrsToList (n: v: "${n}=${v}") attrs;

          appEnv = lib.concatMapAttrs (_: value: value.environment) app.services.components;

          # imageConfig.Env follows OCI spec: list of "K=V" strings
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
            ) (config.imageConfig.Env or [ ])
          );

          # NOTE: we merge Attrs to remove duplicate keys
          envList = appEnv // containerEnv;
        in
        envAttrsToList envList;
    };
  };

  startup.runOnStartup = lib.mkIf (config.setup != "") (
    pkgs.writeShellScript "container-setup" config.setup
  );
}
