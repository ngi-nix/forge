{
  config,
  pkgs,
  lib,
  ...
}:

let
  crossPkgs = pkgs.pkgsCross.riscv64;
in

{
  name = "felix86";
  version = "26.04";
  description = "x86 and x86-64 userspace emulator for RISC-V Linux.";
  homePage = "https://github.com/OFFTKP/felix86";
  mainProgram = "felix86";
  license = lib.licenses.mit;

  source = {
    git = "github:OFFTKP/felix86/26.04";
    hash = "sha256-onhPibvO74yo95zop7EhG+EILn4M70X9ivhS9I+fIBY=";
  };

  build.standardBuilder = {
    enable = true;
    stdenv = crossPkgs.stdenv;
    packages.build = with crossPkgs; [
      cmake
      pkg-config
    ];
    packages.run = with crossPkgs; [
      libGL
      libx11
      vulkan-loader
      vulkan-headers
    ];
  };

  build.extraAttrs = {
    cmakeFlags = [
      (lib.cmakeBool "ZYDIS_BUILD_DOXYGEN" false)
      (lib.cmakeBool "BUILD_TESTS" true)
    ];
    installPhase = ''
      runHook preInstall
      install -Dm755 felix86 $out/bin/felix86
      runHook postInstall
    '';
  };

  # TODO:
  test.script = "";
}
