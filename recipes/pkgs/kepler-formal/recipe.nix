{
  lib,
  pkgs,
  ...
}:

{
  pkgs.kepler-formal = {
    version = "0-unstable-2026-07-17";
    description = "Formal Verification tool for Verilog and Naja interchange format.";
    homePage = "https://github.com/keplertech/kepler-formal";
    mainProgram = "kepler-formal";
    license = lib.licenses.gpl3Only;

    source = {
      git = "github:keplertech/kepler-formal/6c2af237760317480f07f584a166ba00b5b49cf3";
      submodules = true;
      hash = "sha256-IRdMbWSzu+WRcTMe+l9Wjn2iXC4urkUF4cpytjM0BfI=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = [
        pkgs.bison
        pkgs.boost
        pkgs.capnproto
        pkgs.cmake
        pkgs.flex
        pkgs.onetbb
        pkgs.pkg-config
        pkgs.python3
        pkgs.spdlog
        pkgs.zlib
      ];
      packages.run = [
        pkgs.capnproto
        pkgs.onetbb
        pkgs.python3
        pkgs.zlib
      ];
      packages.check = [
        pkgs.ctestCheckHook
      ];
    };

    build.extraAttrs = {
      # Tests use shared tmpDir paths and are not safe to run in parallel
      doCheck = true;
      ctestFlags = [ "-j1" ];
    };

    test.script = ''
      kepler-formal --help | grep "Usage: kepler-formal"
    '';
  };
}
