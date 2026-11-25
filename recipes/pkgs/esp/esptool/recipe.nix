{
  lib,
  pkgs,
  config,
  ...
}:

{
  pkgs.esptool = {
    version = "5.3.1";
    description = "Serial utility for flashing, provisioning, and interacting with Espressif SoCs.";
    homePage = "https://github.com/espressif/esptool";
    mainProgram = "esptool";
    license = lib.licenses.gpl2Plus;

    source = {
      git = "github:espressif/esptool/v${config.pkgs.esptool.version}";
      hash = "sha256-oHQ6rkMnzvjtP/dg+tyc7Dw+D/WuWDqRwqePKBBnjCw=";
    };

    build.builders.python = {
      enable = true;
      packages = {
        build-system = [ pkgs.python3Packages.setuptools ];
        dependencies = with pkgs.python3Packages; [
          bitstring
          click
          cryptography
          intelhex
          pyserial
          pyyaml
          reedsolo
          rich-click
        ];
      };
      importsCheck = [ "esptool" ];
    };

    build.phases = {
      install.script.post = ''
        rm -f $out/bin/*.py
      '';
    };

    test.script = ''
      esptool version | grep -q "${config.pkgs.esptool.version}"
      espefuse --help > /dev/null
      espsecure --help > /dev/null
    '';
  };
}
