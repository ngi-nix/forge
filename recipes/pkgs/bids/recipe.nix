{
  config,
  pkgs,
  lib,
  ...
}:
let
  recipe = config.pkgs.bids;
in
{
  pkgs.bids = {
    version = "0.3.1";
    description = "Tooling to analyse ELF binaries and extract key features for indexing and searching.";
    homePage = "https://github.com/APH10/BIDS";
    mainProgram = "bids-analyser";
    license = lib.licenses.asl20;

    source = {
      git = "github:APH10/BIDS/v0.3.1";
      hash = "sha256-2uuaovTQ8tLcGY3XII4Iws1wg7GYseM73LE7nXIkD6o=";
    };

    build.pythonAppBuilder = {
      enable = true;
      packages = {
        build-system = [ pkgs.python3Packages.setuptools ];
        dependencies = with pkgs.python3Packages; [
          pyelftools
          typecode-libmagic
          typecode
          lib4sbom
          tantivy
          textual
        ];
      };
    };

    build.extraAttrs = {
      postPatch = ''
        # using typecode-libmagic instead of typecode-libmagic-system-provided
        # as typecode-libmagic nix packages already uses system provided library from pkgs.file
        substituteInPlace requirements.txt \
          --replace-fail "typecode-libmagic-system-provided; python_version >= \"3.10\"" "typecode-libmagic; python_version >= \"3.10\""
      '';
    };

    test.script = ''
      version=${recipe.version}
      bids-analyser --version | grep -q $version
      bids-scan --version | grep -q $version
      bids-search --version | grep -q $version
      sbom4bids --version | grep -q $version
    '';
  };
}
