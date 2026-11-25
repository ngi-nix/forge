{
  lib,
  pkgs,
  config,
  ...
}:

{
  pkgs.esp-idf-monitor = {
    version = "1.10.0";
    description = "Serial monitor for ESP-IDF applications.";
    homePage = "https://github.com/espressif/esp-idf-monitor";
    mainProgram = "idf-monitor";
    license = lib.licenses.asl20;

    source = {
      git = "github:espressif/esp-idf-monitor/v${config.pkgs.esp-idf-monitor.version}";
      hash = "sha256-ahf/4YEvguwk8F4TPWQJkDmRwWj8yLIKMsj2AOVAT+g=";
    };

    build.builders.python = {
      enable = true;
      packages = {
        build-system = [ pkgs.python3Packages.setuptools ];
        dependencies = with pkgs.python3Packages; [
          pkgs.esp-idf-panic-decoder
          pkgs.esp-pylib
          pyelftools
          pyserial
          rich
          rich-click
        ];
      };
      relaxDeps = [ "esp-coredump" ];
      importsCheck = [ "esp_idf_monitor" ];
    };

    build.phases.install.script.post = ''
      ln -s $out/bin/idf-monitor $out/bin/esp-idf-monitor
    '';

    build.extraAttrs = {
      pythonRemoveDeps = [ "esp-coredump" ];
    };

    test.script = ''
      idf-monitor --help | grep -q "idf_monitor"
      esp-idf-monitor --help | grep -q "idf_monitor"
    '';
  };
}
