{
  pkgs,
  config,
  lib,
  ...
}:
let
  recipe = config.pkgs.prismafs;
in
{
  pkgs.prismafs = {
    version = "1.6.0";
    description = "Lightweight, portable userspace filesystem with isolated session layer.";
    homePage = "https://github.com/goranb131/prismaFS";
    mainProgram = "prismafs";
    license = lib.licenses.asl20;

    source = {
      git = "github:goranb131/prismaFS/v${recipe.version}";
      hash = "sha256-7zgHE240KryrIXRGwa+Y6Veph3mDFc0Ii7KIbwTVIhY=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = with pkgs; [
        gnumake
        pkg-config
      ];
      packages.run = with pkgs; [
        fuse3
      ];
    };

    build.extraAttrs = {
      patches = [
        ./001-fix-fuse-flag-darwin.patch
      ];
      postPatch = ''
        #remove the binary shipped with the source
        rm -rf prismafs 
      '';
      installFlags = [ "PREFIX=$(out)" ];

      passthru.tests.nixos = pkgs.testers.runNixOSTest {
        name = "prismafs-nixos";

        nodes.machine = {
          environment.systemPackages = [ recipe.result.derivation ];
          boot.kernelModules = [ "fuse" ];
        };

        testScript = ''
          machine.wait_for_unit("multi-user.target")

          machine.succeed("""
            # see: https://github.com/goranb131/prismaFS/blob/main/test-script.sh
            BASE=$(mktemp -d)
            SESSION=$(mktemp -d)
            MNT=$(mktemp -d)
            CONF=$(mktemp)

            echo "base $BASE" > $CONF
            echo "session $SESSION" >> $CONF
            echo "hello" > $BASE/testfile.txt

            prismafs -c $CONF $MNT
            sleep 0.5

            ls $MNT | grep testfile.txt
            cat $MNT/testfile.txt | grep hello
            cat $MNT/dev/cpu

            umount $MNT
          """)
        '';
      };

    };

    test.script = ''
      prismafs -v | grep -q ${recipe.version}
    '';
  };
}
