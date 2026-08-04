{
  app,

  service,
  serviceName,
  runtimeConfig ? {
    setup = "";
    packages = [ ];
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
          echo '${serviceName}:x:${uid}:${gid}:${serviceName}:${service.process.stateDir}:/sbin/nologin' >> $out/etc/passwd
          echo 'root:x:0:' > $out/etc/group
          echo '${serviceName}:x:${gid}:' >> $out/etc/group
          echo 'root:!:0::::::' > $out/etc/shadow
          echo '${serviceName}:!:1::::::' >> $out/etc/shadow
          echo 'hosts: files dns' > $out/etc/nsswitch.conf
        '';
      in
      pkgs.buildEnv {
        name = "runtime-bins";
        paths = [
          etcFiles
        ]
        ++ service.process.packages
        ++ runtimeConfig.packages
        ++ service.healthcheck.packages;
        pathsToLink = [
          "/bin"
          "/etc"
        ];
      };

    imageConfig = {
      WorkingDir = service.process.stateDir;
      User = if service.process.user == "root" then "root" else serviceName;
      Volumes = {
        "${service.process.stateDir}" = { };
      };
      Env =
        let
          envAttrsToList = attrs: lib.mapAttrsToList (n: v: "${n}=${v}") attrs;
        in
        envAttrsToList service.process.environment;
      Labels = {
        ngi-forge = "true";
        "ngi-forge.type" = "component";
      };
    };
  };

  startup.runOnStartup = lib.mkIf (runtimeConfig.setup != "") (
    pkgs.writeShellScript "container-setup" runtimeConfig.setup
  );
}
