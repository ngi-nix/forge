{
  pkgs,
  lib,
  ...
}:

{
  pkgs.tau-tower = {
    version = "0.2.101-unstable-2026-08-23";
    description = "Webradio server - broadcasts audio source to clients.";
    homePage = "https://github.com/tau-org/tau-tower";
    mainProgram = "tau-tower";
    license = lib.licenses.eupl12;

    source = {
      git = "github:tau-org/tau-tower/89c750a04cfce9024aea2933981dd386ea001733";
      hash = "sha256-odZVP0vjRffbzBUFZplGY7gtOJOJEd1mDYUk6ySuZ/0=";
    };

    build.builders.rust = {
      enable = true;
      packages = {
        build = with pkgs; [
          perl
          pkg-config
        ];
      };
      cargoHash = "sha256-Qv97FTiccfQSBI2OBfl31p3oF/JCL/+UXkK+owuByDY=";
    };

    test.script = ''
      tau-tower --version
    '';
  };
}
