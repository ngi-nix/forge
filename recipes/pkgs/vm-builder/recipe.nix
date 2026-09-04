{
  pkgs,
  config,
  lib,
  ...
}:
let
  recipe = config.pkgs.vm-builder;
in
{
  pkgs.vm-builder = {
    version = "0.3.0";
    description = "Portable, isolated tool for building virtual machines from text-based configurations.";
    homePage = "https://codeberg.org/uvm/vm-builder";
    mainProgram = "vm-builder";
    license = lib.licenses.agpl3Only;

    source = {
      git = "codeberg:uvm/vm-builder/a54690acd366370f75583c5557cf2823faece894";
      hash = "sha256-QytC1qbcBnjnpn6HSoRPTCZrQmQaacK8J4thtawW0y4=";
    };

    build.rustPackageBuilder = {
      enable = true;
      cargoHash = "sha256-ySkWyWuS5+J50xOxbN/UrPS3nP32tXuqdrrvu4fDyEQ=";
      packages.build = [
        pkgs.makeWrapper
      ];
    };

    build.extraAttrs = {
      # Tests are disabled until fixed upstream
      doCheck = false;

      # Only using QEMU as the backend; VirtualBox backend is only supported on macOS.
      postFixup = ''
        wrapProgram $out/bin/vm-builder \
          --prefix PATH : ${lib.makeBinPath [ pkgs.qemu_kvm ]} \
          --prefix XDG_DATA_DIRS : ${pkgs.qemu_kvm}/share
      '';
    };

    test.script = "vm-builder --version | grep -q ${recipe.version}";
  };
}
