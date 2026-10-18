{
  lib,
  pkgs,
  ...
}:

{
  pkgs.kepler-formal = {
    version = "0-unstable-2026-10-15";
    description = "Formal Verification tool for Verilog and Naja interchange format.";
    homePage = "https://github.com/keplertech/kepler-formal";
    mainProgram = "kepler-formal";
    license = lib.licenses.gpl3Only;

    source = {
      git = "github:keplertech/kepler-formal/8170b6a4fc01b6793c3d6efeb70775704fca797e";
      submodules = true;
      hash = "sha256-7viUQyWGKILiSr16cd2Yla2XBetKKOpCw9x5xA6CXG0=";
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
      postPatch = ''
        find thirdparty/naja/thirdparty/slang \( -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) -exec sed -i 's|#include <fmt/core.h>|#include <fmt/core.h>\n#include <fmt/format.h>\n#include <fmt/ranges.h>|g' {} +
      '';
    };

    test.script = ''
      kepler-formal --help | grep "Usage: kepler-formal"
    '';
  };
}
