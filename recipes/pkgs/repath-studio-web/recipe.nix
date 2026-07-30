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
      hash = "sha256-uHGF/SEbKZF6Ax1yrXYoAjXH5k6PzKF4aB85TXGJvk4=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = [
        pkgs.asar
      ];
    };

    build.extraAttrs = {
      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/repath-studio-web
        asar extract "${pkgs.repath-studio}/share/repath-studio/app.asar" extracted
        cp -r extracted/resources/public/* $out/share/repath-studio-web/
        cp -r $src/schema-explorer $out/share/repath-studio-web/schema-explorer

        runHook postInstall
      '';
    };

    test.script = ''
      test -f "${pkgs.repath-studio-web}/share/repath-studio-web/index.html"
      test -f "${pkgs.repath-studio-web}/share/repath-studio-web/schema-explorer/index.html"
    '';
  };
}
