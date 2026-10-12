{
  lib,
  pkgs,
  ...
}:

{
  pkgs.kepler-formal = {
    version = "0-unstable-2026-10-10";
    description = "Formal Verification tool for Verilog and Naja interchange format.";
    homePage = "https://github.com/keplertech/kepler-formal";
    mainProgram = "kepler-formal";
    license = lib.licenses.gpl3Only;

    source = {
      git = "github:keplertech/kepler-formal/0e3019d4fa5d365771ba783a8c4f34f58e2e19f6";
      submodules = true;
      hash = "sha256-RXwX/q5D1J6t0Ckj/RvmgxKKmDqUlwoWf8JKMZWkx4k=";
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
