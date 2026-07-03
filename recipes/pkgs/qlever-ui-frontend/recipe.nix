{
  config,
  ...
}:

{
  pkgs.qlever-ui-frontend = {
    description = "Frontend for QLever UI.";
    inherit (config.pkgs.qlever-ui)
      source
      version
      homePage
      license
      ;

    build.npmPackageBuilder = {
      enable = true;
      npmDepsHash = "sha256-Zq7+HLPO+lVYJflz7SK1rTgQtNSgbx2mZ7wFd6McBCo=";
    };

    build.extraAttrs = {
      installPhase = ''
        runHook preInstall
        cp -r ./backend/static/wasm $out
        runHook postInstall
      '';
    };
  };
}
