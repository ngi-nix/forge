{
  pkgs,
  ...
}:

{
  apps.sudo-rs = {
    displayName = "sudo-rs";
    description = "Memory-safe implementation of sudo and su.";
    usage = ''
      sudo-rs is a memory-safe Rust reimplementation of the sudo and su utilities.

      #### Example

      Run a command as root

      ```
      sudo <command>
      ```

      Switch to another user

      ```
      su - <username>
      ```

      Edit the sudoers file safely

      ```
      visudo
      ```
    '';

    links = {
      source = "https://github.com/trifectatechfoundation/sudo-rs";
    };

    ngi.grants = {
      Core = [
        "sudo-rs"
      ];
    };
    icon = ./icon.svg;

    programs = {
      mainPackage = pkgs.sudo-rs;
      packages = [
        pkgs.sudo-rs
      ];

      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };
  };
}
