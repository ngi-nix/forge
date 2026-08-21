{
  pkgs,
  ...
}:
{
  apps.prismafs = {
    displayName = "PrismaFS";
    description = "Lightweight, portable userspace filesystem with isolated session layer.";
    usage = ''
      #### Running PrismaFS

      1. Set up the required environment variables:
        - `BASE_LAYER_DIR`: The directory to be used as the base layer (e.g., `/`).
        - `SESSION_LAYER_DIR`: The directory to store session-specific changes (e.g., `/tmp/prismafs_session`).

        Example:

      ```export BASE_LAYER_DIR=/```
      ```export SESSION_LAYER_DIR=/tmp/prismafs_session```

      2. Mount PrismaFS to a directory:

      ```mkdir /tmp/prismafs_mount```
      ```./prismafs /tmp/prismafs_mount```

      3. Use the mounted directory (`/tmp/prismafs_mount`) to view and modify files:
        - Changes in this directory are isolated to the session layer.
        - Base layer files remain unmodified.

      #### Cleaning Up

      To unmount PrismaFS:

      ```umount /tmp/prismafs_mount```

      Or:

      ```fusermount -u /tmp/prismafs_mount```

    '';

    links = {
      source = "https://github.com/goranb131/prismaFS";
    };

    ngi.grants = {
      Commons = [
        "PrismaFS"
      ];
    };

    programs = {
      mainPackage = pkgs.prismafs;
      packages = [ pkgs.prismafs ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    # Note: An end-to-end test is in the passthru.tests.nixos package
    # but needs to run in a nixos vm
    test.programs.script = ''
      prismafs -v | grep -q ${pkgs.prismafs.version}
    '';

  };
}
