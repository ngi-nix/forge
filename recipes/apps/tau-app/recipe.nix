{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "tau-app";
  description = "Web radio streaming system - tau-tower server and tau-radio client";

  usage = ''
    ## Tau Radio Streaming System

    This app provides both the tau-tower server and tau-radio client.

    ### tau-tower (Server)
    Run as a service to broadcast audio to clients:
    - Listens on port 3001 by default
    - Broadcasts on port 3002 by default
    - Configuration: ~/.config/tau/config.toml

    ### tau-radio (Client)
    Capture audio from your device and stream to tau-tower:
    ```
    tau-radio --username <user> --password <pass> --host <server-ip>
    ```

    ### Default Ports
    - Server listen: 3001
    - Broadcast: 3002
  '';

  programs = {
    components.default = {
      requirements = [
        pkgs.mypkgs.tau-radio
        pkgs.mypkgs.tau-tower
      ];
    };

    runtimes.shell = {
      enable = true;
    };
  };

  services = {
    components.tau-tower = {
      command = pkgs.mypkgs.tau-tower;

      configData."tau/tower.toml" = {
        source = "/etc/tau/tower.toml";
        path = "tau/tower.toml";
      };

      configData."credstore/tau.PASSWORD" = {
        source = "/etc/credstore/tau.PASSWORD";
        path = "tau/PASSWORD";
      };
    };

    runtimes = {
      container = {
        enable = true;
        requirements = [
          pkgs.mypkgs.tau-tower
          pkgs.bash
          pkgs.coreutils
          pkgs.gnused
        ];
        # NOTE: `tau` expects its config to be under `XDG_CONFIG_HOME/tau`
        imageConfig.WorkingDir = "/tau";
        imageConfig.Env = [ "XDG_CONFIG_HOME=/" ];
        setup =
          let
            configFile = "/etc/tau/tower.toml";
            passwordFile = "/etc/credstore/tau.PASSWORD";
          in
          ''
            install -Dm600 "${configFile}" /tau/tower.toml
            sed -i "s/@password@/$(cat "${passwordFile}")/" /tau/tower.toml
          '';
        composeFile = ./compose.yaml;
      };

      nixos = {
        enable = true;
        extraConfig =
          let
            configFile = "/etc/system-services/tau-tower/tau/tower.toml";
            passwordFile = "/etc/system-services/tau-tower/credstore/tau.PASSWORD";
          in
          {
            # WARN: !!! Don't use in production !!!
            #
            # This will copy your secrets to the Nix store, which is world-readable.
            #
            # Instead, manually put your secret files in the systemd credentials
            # store (e.g. `/etc/credstore/`, `/run/credstore/`, ...).
            #
            # For more information on this topic, see:
            # https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#ImportCredential=GLOB
            environment.etc."credstore/tau.PASSWORD".source = ./password;

            environment.etc."tau/tower.toml".source = ./config.toml;

            systemd.services.tau-tower = {
              description = "Tau Webradio Server";
              serviceConfig = {
                DynamicUser = true;
                User = "tau-tower";
                Group = "tau-tower";
                Restart = "on-failure";
                RestartSec = 5;
                StateDirectory = "tau-tower";
                LoadCredential = [
                  "password_file:${passwordFile}"
                ];
              };
              unitConfig = {
                StartLimitBurst = 5;
                StartLimitInterval = 100;
              };
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              environment.XDG_CONFIG_HOME = "/var/lib/tau-tower";
              preStart = ''
                install -Dm600 ${configFile} $XDG_CONFIG_HOME/tau/tower.toml
                sed -i "s/@password@/$(cat $CREDENTIALS_DIRECTORY/password_file)/" $XDG_CONFIG_HOME/tau/tower.toml
              '';
              postStop = ''
                rm -f $XDG_CONFIG_HOME/tau/tower.toml
              '';
            };

            environment.systemPackages = [
              pkgs.mypkgs.tau-radio
              pkgs.mypkgs.tau-tower
            ];
          };
        vm.forwardPorts = [
          "3001:3001"
          "3002:3002"
        ];
      };
    };
  };

}
