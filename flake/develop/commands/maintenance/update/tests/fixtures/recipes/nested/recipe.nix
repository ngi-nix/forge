{
  lib,
  pkgs,
  ...
}:

{
  pkgs.nested = {
    version = "1.2.3";
    description = "Recipe with nested builder config and a version literal in scripts.";
    homePage = "https://github.com/example/nested";
    license = lib.licenses.gpl3Only;

    source = {
      git = "github:example/nested/v1.2.3";
      hash = "sha256-HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH=";
    };

    build.builders.standard = {
      enable = true;
      packages.build = [
        pkgs.cmake
        pkgs.ninja
        pkgs.pkg-config
      ];
    };

    build.extraAttrs = {
      postPatch = ''
        substituteInPlace meson.build \
          --replace-fail "version = \"1.2.3\"" "version = \"${version}\""
      '';

      cmakeFlags = [
        (lib.cmakeBool "ENABLE_TESTS" true)
      ];
    };

    build.phases = {
      check.enable = true;
    };

    test.script = ''
      echo 'version = "1.2.3"'
      nested --version
    '';
  };
}
