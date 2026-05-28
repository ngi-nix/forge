{
  app,

  service,
  serviceName,
  runtimeConfig ? {
    setup = "";
    packages = [ ];
    imageConfig = { };
  },
  pkgs,
  lib,
  ...
}:
{
  binName = "${app.name}-service";

  container = {
    copyToRoot =
      let
        uid = "1001";
        gid = "1001";
        etcFiles = pkgs.runCommand "etc-${serviceName}" { } ''
          mkdir -p $out/etc
          echo 'root:x:0:0:root:/root:/bin/sh' > $out/etc/passwd
          echo '${serviceName}:x:${uid}:${gid}:${serviceName}:${service.stateDir}:/sbin/nologin' >> $out/etc/passwd
          echo 'root:x:0:' > $out/etc/group
          echo '${serviceName}:x:${gid}:' >> $out/etc/group
          echo 'root:!:0::::::' > $out/etc/shadow
          echo '${serviceName}:!:1::::::' >> $out/etc/shadow
          echo 'hosts: files dns' > $out/etc/nsswitch.conf
        '';
      in
      pkgs.buildEnv {
        name = "runtime-bins";
        paths = service.packages ++ runtimeConfig.packages ++ [ etcFiles ];
        pathsToLink = [
          "/bin"
          "/etc"
        ];
      };

    imageConfig = {
      WorkingDir = service.stateDir;
      User = if service.user == "root" then "root" else serviceName;
    }
    // runtimeConfig.imageConfig
    // {
      Volumes = (runtimeConfig.imageConfig.Volumes or { }) // {
        "${service.stateDir}" = { };
      };
      Env =
        let
          # { K = "V"; } -> [ "K=V" ]
          envAttrsToList = attrs: lib.mapAttrsToList (n: v: "${n}=${v}") attrs;

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
            ) (runtimeConfig.imageConfig.Env or [ ])
          );

          # NOTE: we merge Attrs to remove duplicate keys
          envList = service.environment // containerEnv;
        in
        envAttrsToList envList;
    };
  };

  startup.runOnStartup = lib.mkIf (runtimeConfig.setup != "") (
    pkgs.writeShellScript "container-setup" runtimeConfig.setup
  );
}
