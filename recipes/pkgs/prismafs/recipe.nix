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
    version = "1.7.1";
    description = "Lightweight, portable userspace filesystem with isolated session layer.";
    homePage = "https://github.com/goranb131/prismaFS";
    mainProgram = "prismafs";
    license = lib.licenses.asl20;

    source = {
      git = "github:goranb131/prismaFS/v1.7.1";
      hash = "sha256-eP1z7+r+vzS1Tg7EYYUtNzjhHKwL1/Z9WWfxRelhEIo=";
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
      postPatch = ''
        #remove the binary shipped with the source
        rm -rf prismafs
      '';
      installFlags = [ "PREFIX=$(out)" ];
    };

    test = {
      script = ''
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
      '';
      runner = "nixos";
      nixosConfig.boot.kernelModules = [ "fuse" ];
    };
  };
}
