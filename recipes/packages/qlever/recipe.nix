{
  config,
  pkgs,
  lib,
  ...

}:

let
  deps = {
    fsst = pkgs.fetchFromGitHub {
      owner = "cwida";
      repo = "fsst";
      rev = "b228af6356196095eaf9f8f5654b0635f969661e";
      hash = "sha256-XuE/nalt2HEYaII9NytUs0rCLGHOUFEclO+0h7pu4V0=";
    };
    re2 = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "re2";
      rev = "bc0faab533e2b27b85b8ad312abf061e33ed6b5d";
      hash = "sha256-cKXe8r5MUag/z+seem4Zg/gmqIQjaCY7DBxiKlrnXPs=";
    };
    googletest = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "googletest";
      rev = "7917641ff965959afae189afb5f052524395525c";
      hash = "sha256-Pfkx/hgtqryPz3wI0jpZwlRRco0s2FLcvUX1EgTGFIw=";
    };
    nlohmann-json = pkgs.fetchFromGitHub {
      owner = "nlohmann";
      repo = "json";
      tag = "v3.12.0";
      hash = "sha256-cECvDOLxgX7Q9R3IE86Hj9JJUxraDQvhoyPDF03B2CY=";
    };
    antlr = pkgs.fetchFromGitHub {
      owner = "antlr";
      repo = "antlr4";
      rev = "cc82115a4e7f53d71d9d905caa2c2dfa4da58899";
      hash = "sha256-DxxRL+FQFA+x0RudIXtLhewseU50aScHKSCDX7DE9bY=";
    };
    range-v3 = pkgs.fetchFromGitHub {
      owner = "joka921";
      repo = "range-v3";
      rev = "42340ef354f7b4e4660268b788e37008d9cc85aa";
      hash = "sha256-/17XLLLuEkcqeklVtqlgtu19tNTT3bLRHrU1aOPLhTw=";
    };
    spatialjoin = pkgs.fetchFromGitHub {
      owner = "ad-freiburg";
      repo = "spatialjoin";
      rev = "c358e479ebb5f40df99522e69a0b52d73416020b";
      hash = "sha256-/BQzyCx1KxnOeLLZkvqno2KN/VHAEu228zrsJaqYu/c=";
      fetchSubmodules = true;
    };
    ctre = pkgs.fetchFromGitHub {
      owner = "hanickadot";
      repo = "compile-time-regular-expressions";
      rev = "e34c26ba149b9fd9c34aa0f678e39739641a0d1e";
      hash = "sha256-/44oZi6j8+a1D6ZGZpoy82GHjPtqzOvuS7d3SPbH7fs=";
    };
    abseil = pkgs.fetchFromGitHub {
      owner = "abseil";
      repo = "abseil-cpp";
      rev = "93ac3a4f9ee7792af399cebd873ee99ce15aed08";
      hash = "sha256-a18+Yj9fvDigza4b2g38L96hge5feMwU6fgPmL/KVQU=";
    };
    s2 = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "s2geometry";
      rev = "5b5eccd54a08ae03b4467e79ffbb076d0b5f221e";
      hash = "sha256-VjgGcGgQlKmjUq+JU0JpyhOZ9pqwPcBUFEPGV9XoHc0=";
    };
  };
in

{
  name = "qlever";
  version = "0.5.46";
  description = "Graph database implementing the RDF and SPARQL standards";
  license = lib.licenses.asl20;

  homePage = "https://github.com/ad-freiburg/qlever";
  mainProgram = "qlever";

  source = {
    git = "github:ad-freiburg/qlever/v0.5.46";
    hash = "sha256-UUfSWy1mImmyL7Ha2xCbxm9srdY/rTJS4oUJbJiDtwQ=";
    submodules = true;
  };

  build.standardBuilder = {
    enable = true;
    packages = {
      build = with pkgs; [
        cmake
        pkg-config
        git
      ];
      run = with pkgs; [
        boost
        bzip2
        icu
        openssl
        zlib
        zstd
        jemalloc
      ];
    };
  };

  build.extraAttrs = {
    env = {
      NIX_CFLAGS_COMPILE = "-fno-semantic-interposition";
    };

    cmakeFlags = [
      (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
      (lib.cmakeFeature "LOGLEVEL" "INFO")
      (lib.cmakeBool "USE_PARALLEL" true)
      (lib.cmakeBool "_NO_TIMING_TESTS" true)
      (lib.cmakeBool "JEMALLOC_MANUALLY_INSTALLED" true)
      (lib.cmakeBool "USE_CONAN" false)
      (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_FSST" "${deps.fsst}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_RE2" "${deps.re2}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_GOOGLETEST" "${deps.googletest}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_NLOHMANN-JSON" "${deps.nlohmann-json}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_ANTLR" "${deps.antlr}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_RANGE-V3" "${deps.range-v3}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_SPATIALJOIN" "${deps.spatialjoin}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_CTRE" "${deps.ctre}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_ABSEIL" "${deps.abseil}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_S2" "${deps.s2}")
    ];
  };

  test.script = ''
    qlever-server --help 2>&1 | grep "Options for qlever-server:"
    qlever-index --help 2>&1 | grep "Options for qlever-index:"
  '';
}
