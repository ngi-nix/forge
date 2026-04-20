{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "kepler-formal";
  version = "1.0.0-unstable-2026-04-13";
  description = "Formal Verification tool for Verilog and Naja interchange format.";
  homePage = "https://github.com/keplertech/kepler-formal";
  mainProgram = "kepler-formal";
  license = lib.licenses.gpl3Only;

  source = {
    git = "github:keplertech/kepler-formal/8aff6307f464f2a3020710e0a6cd0e4a0dd6a132";
    submodules = true;
    hash = "sha256-4hmA7d3aTcW2wIa2gzSqVpV/1dPiEDihoCOMDqvxqnU=";
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
}
