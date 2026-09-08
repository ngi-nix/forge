{
  lib,
  pkgs,
  ...
}:
{
  apps.bluetuith = {
    description = "bluetuith is a TUI-based bluetooth connection manager, which can interact with bluetooth adapters and devices.";
    categories = with lib.categories; [ Utility ];
    usage = ''
      bluetuith is a terminal-based Bluetooth connection manager. It works
      out-of-the-box with no configuration required.

      Launch the interactive TUI

      ```bash
      bluetuith
      ```

      Select a specific adapter and connect to a device

      ```bash
      bluetuith --adapter=hci0 --connect-bdaddr="AA:BB:CC:DD:EE:FF"
      ```

      Configuration is optional and uses the HJSON format. Generate a config
      in `$XDG_CONFIG_HOME/bluetuith` with the following command:

      ```bash
      bluetuith --generate
      ```

      Run `bluetuith --help` for more information on the available options.
    '';

    links = {
      source = "https://github.com/bluetuith-org/bluetuith";
      docs = "https://bluetuith-org.github.io/bluetuith/Configuration.html";
      website = "https://bluetuith-org.github.io/bluetuith";
    };

    ngi.grants = {
      Core = [
        "bluetuith"
      ];
    };

    programs = {
      mainPackage = pkgs.bluetuith;
      packages = [ pkgs.bluetuith ];
      runtimes.shell.enable = true;
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      bluetuith --version | grep -q ${pkgs.bluetuith.version}
    '';
  };
}
