{
  lib,
  pkgs,
  ...
}:

{
  pkgs.kepler-formal = {
    version = "0-unstable-2026-06-11";
    description = "Formal Verification tool for Verilog and Naja interchange format.";
    homePage = "https://github.com/keplertech/kepler-formal";
    mainProgram = "kepler-formal";
    license = lib.licenses.gpl3Only;

    source = {
      git = "github:keplertech/kepler-formal/5a9e7edded7e8d185bc0842e38f2852df814f0d5";
      submodules = true;
      hash = "sha256-LGOeY0K0cke/Egm7J32YsTIAGn6j/okTWJLYZf8nmTo=";
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
        pkgs.zlib
      ];
      packages.run = [
        pkgs.flex
        pkgs.boost
        pkgs.capnproto
        pkgs.onetbb
        pkgs.python3
        pkgs.zlib
        pkgs.spdlog
      ];
      packages.check = [
        pkgs.ctestCheckHook
      ];
    };

    phases = {
      check.enable = true;
    };

    build.extraAttrs = {
      # Tests use shared tmpDir paths and are not safe to run in parallel
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
