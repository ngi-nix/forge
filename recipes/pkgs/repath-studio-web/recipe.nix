{
  pkgs,
  lib,
  ...
}:

{
  pkgs.repath-studio-web = {
    version = pkgs.repath-studio.version;
    description = "Web app and schema explorer for Repath Studio.";
    homePage = "https://repath.studio";
    license = lib.licenses.gpl3Only;

    source = {
      git = "github:repath-studio/repath-studio/v${pkgs.repath-studio.version}";
      hash = "sha256-Jjx5vz7k6koSftw3oPHHAWVjwz+wZ1Jdc3cLZcmbjHI=";
    };

    build.builders.standard = {
      enable = true;
      packages.build = [
        pkgs.asar
      ];
    };

    build.phases = {
      unpack.enable = false;
      configure.enable = false;
      build.enable = false;

      install.script.main = ''
        mkdir -p $out/share/repath-studio-web
        asar extract "${pkgs.repath-studio}/share/repath-studio/app.asar" extracted
        cp -r extracted/resources/public/* $out/share/repath-studio-web/
        cp -r $src/schema-explorer $out/share/repath-studio-web/schema-explorer
      '';
    };

    test.script = ''
      test -f "${pkgs.repath-studio-web}/share/repath-studio-web/index.html"
      test -f "${pkgs.repath-studio-web}/share/repath-studio-web/schema-explorer/index.html"
    '';
  };
}
