{
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.vm-builder;
in
{
  apps.vm-builder = {
    displayName = "vm-builder";
    description = "Portable, isolated tool for building virtual machines from text-based configurations.";
    usage = ''
      vm-builder is a tool for building VM images using minimal hypervisor
      requirements (a serial console and virtual hard disks).

      #### Setup & Configuration

      List available build configurations and existing images

      ```bash
      vm-builder list
      ```

      Import a build configuration repository, from a directory path or an
      `import.xml` file

      ```bash
      vm-builder import --path /path/to/config
      ```

      #### Build an Image

      Build a target VM image from an imported repository configuration

      ```bash
      vm-builder build --repo <repository-name> --name <config-name>
      ```

      #### Example

      Download the example configuration from the
      [vm-builder repository](https://codeberg.org/uvm/vm-builder), import it,
      and build a sample image

      ```bash
      vm-builder import --path examples/vm-repo
      vm-builder build --repo vm-repo --arch x86_64 --name linux-busybox --version 2024-07-30
      ```

      For complete job configuration syntax (partitioning, formatting, commands,
      and exports), refer to the [vm-builder documentation](${recipe.links.docs}).
    '';

    links = {
      source = "https://codeberg.org/uvm/vm-builder";
      docs = "https://vm-builder.readthedocs.io/en/latest";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Core = [
        "vm-builder"
      ];
    };

    programs = {
      mainPackage = pkgs.vm-builder;
      packages = [ pkgs.vm-builder ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs.packages = [
      pkgs.writableTmpDirAsHomeHook
    ];

    test.programs.script = ''
      cp -R ${pkgs.vm-builder.src}/. .
      chmod -R u+w .
      vm-builder import --path import.xml
      vm-builder build \
          --repo vm-repo \
          --arch x86_64 \
          --name linux-busybox \
          --version 2024-07-30
    '';
  };
}
