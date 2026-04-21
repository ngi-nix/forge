{
  config,
  lib,
  pkgs,
  ...
}:

let
  # pyahocorasick must be compiled in bytes mode for bang to work
  pyahocorasick-bytes = pkgs.python3Packages.pyahocorasick.overridePythonAttrs (old: {
    env = (old.env or { }) // {
      AHOCORASICK_BYTES = "1";
    };
  });
in

{
  name = "bang";
  version = "0-master-2026-04-14";
  description = "Binary Analysis Next Generation framework for recursive unpacking and analysis of binary files.";
  homePage = "https://github.com/armijnhemel/binaryanalysis-ng";
  mainProgram = "bang";
  license = lib.licenses.gpl3Only;

  source = {
    git = "github:armijnhemel/binaryanalysis-ng/6e9b43af6d23e5a8f201ed355511a620d6f2f52e";
    hash = "sha256-nTizHleLiCiyVguxmXa3t3MckZ3IiMSjGdza4cCQZhs=";
  };

  build.pythonAppBuilder = {
    enable = true;
    packages.build-system = with pkgs.python3Packages; [
      setuptools
      wheel
    ];
    packages.build = [
      pkgs.kaitai-struct-compiler
    ];
    packages.dependencies = with pkgs.python3Packages; [
      deepdiff
      kaitaistruct
      parameterized
      tlsh
      python-snappy
      pillow
      lz4
      icalendar
      dockerfile-parse
      defusedxml
      mutf8
      brotli
      pyaxmlparser
      pyyaml
      telfhash
      python-lzo
      zstd
      protobuf
      click
      rich
      pyahocorasick-bytes
    ];
    # The upstream test suite imports modules that were deleted/renamed
    # (UnpackResults, bang.signatures) and has never been updated.
    # Tests are disabled until upstream fixes the test suite.
    # packages.check = with pkgs.python3Packages; [
    #   pytestCheckHook
    # ];
    relaxDeps = [
      "kaitaistruct"
      "python-tlsh"
    ];
    importsCheck = [ "bang" ];
  };

  build.extraAttrs = {
    postPatch = ''
      # setup.cfg lists python-tlsh but nixpkgs provides it as tlsh
      substituteInPlace setup.cfg \
        --replace-fail "python-tlsh" "tlsh"

      # bang package uses implicit namespace packages (no __init__.py),
      # so switch to find_namespace_packages to ensure it's included in the wheel
      substituteInPlace setup.cfg \
        --replace-fail "packages = find:" "packages = find_namespace:"

      # pytest is incorrectly listed in install_requires upstream
      substituteInPlace setup.cfg \
        --replace-fail $'\tpytest\n' ""
    '';

    preBuild = ''
      # Compile Kaitai Struct .ksy parsers to Python (bang/parsers/**/*.py)
      make -C src
    '';
  };

  test.script = ''
    echo "Test data" > test-file.txt
    bang scan -v -u bang-results ./test-file.txt
  '';
}
