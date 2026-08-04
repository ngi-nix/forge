{
  pkgs,
  lib,
  ...
}:

{
  pkgs.tau-tower = {
    version = "0.2.101-unstable-2026-06-11";
    description = "Webradio server - broadcasts audio source to clients.";
    homePage = "https://github.com/tau-org/tau-tower";
    mainProgram = "tau-tower";
    license = lib.licenses.eupl12;

    source = {
      git = "github:tau-org/tau-tower/0747f38f06cfc7d3b412c49b7514d1a3e89b7145";
      hash = "sha256-vbUR2ZfnomUkWdz2xdFReR6B0lzz4dKM88RonAWu994=";
    };

    build.rustPackageBuilder = {
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
