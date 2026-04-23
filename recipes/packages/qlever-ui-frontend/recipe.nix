{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "qlever-ui-frontend";
  version = "0-unstable-2026-04-16";
  description = "Frontend for QLever UI";
  homePage = "https://github.com/qlever-dev/qlever-ui";
  license = lib.licenses.asl20;

  source = {
    git = "github:qlever-dev/qlever-ui/b12823ffd25f0c9ebdc530ebd16868e7389ef0fa";
    hash = "sha256-aN4vj5zYy/rkfhEylHd5wYGxwEFaZCSnpZIIYhSQMeo=";
  };

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

  test.script = ''
    test -f ${pkgs.mypkgs.qlever-ui-frontend}/formatter/index.js
  '';
}
