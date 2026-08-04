{
  lib,
  ...
}:
{
  pkgs.pnut = {
    version = "1.1";
    description = "C to POSIX shell transpiler for reproducible and auditable bootstrapping of GCC from a minimal seed.";
    homePage = "https://github.com/udem-dlteam/pnut";
    mainProgram = "pnut";
    license = lib.licenses.bsd2;

    source = {
      git = "github:udem-dlteam/pnut/pnut-1.1";
      hash = "sha256-q0JoW8Tw25m+Hp9W/LxzC3yt78J1AmeV1G3h41RHIOI=";
    };

    build.standardBuilder = {
      enable = true;
    };

    build.extraAttrs = {
      installPhase = ''
        mkdir -p $out/bin
        make install PREFIX=$out
      '';
    };

    test.script = ''
      echo "int main(void) { return 0; }" > /tmp/test.c
      pnut /tmp/test.c
    '';
  };
}
