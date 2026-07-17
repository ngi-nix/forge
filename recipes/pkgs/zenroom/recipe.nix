{
  lib,
  pkgs,
  ...
}:

# TODO: remove when this PR propagates to forge:
# https://nixpkgs-tracker.ocfox.me/?pr=541778

{
  pkgs.zenroom = {
    version = "5.37.2";
    description = "No-code cryptographic virtual machine.";
    homePage = "https://zenroom.org";
    mainProgram = "zenroom";
    license = with lib.licenses; [
      agpl3Plus
      asl20 # lib/milagro-crypto-c, lib/mlkem, lib/longfellow-zk, lib/mayo
      bsd3 # lib/zstd
      cc0 # lib/pqclean, lib/ed25519-donna
      mit # lib/lua54, src/varint.*, lib/mayo
    ];

    source = {
      git = "github:dyne/Zenroom/v5.37.2";
      hash = "sha256-gZKNtv3A8cQ/czoVcwUxcaTOJ6dmka5EZ/YKhXy84xw=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = with pkgs; [
        cmake
        which
        xxd
      ];
      packages.run = with pkgs; [
        readline
      ];
    };

    build.extraAttrs = {
      postPatch = ''
        patchShebangs build/embed-lualibs
      '';

      __structuredAttrs = true;
      dontUseCmakeConfigure = true; # cmake is a dependency, but we use make to build
      strictDeps = true;

      buildFlags =
        with pkgs.stdenv.hostPlatform;
        lib.optionals (isLinux && !isMusl) [
          "linux-lib"
          "linux-exe"
        ]
        ++ lib.optionals (isLinux && isMusl) [
          "musl"
        ]
        ++ lib.optionals isDarwin [
          "osx-lib"
          "osx-exe"
        ]
        ++ lib.optionals (isUnix && !isLinux && !isDarwin) [
          "posix-lib"
          "posix-exe"
        ];

      hardeningDisable = [ "format" ]; # -Werror=format-security

      env.PREFIX = "";
      env.DESTDIR = placeholder "out";

      preInstall = ''
        mkdir -p $out/{bin,share}
      '';

      postInstall = ''
        install -D libzenroom${pkgs.stdenv.hostPlatform.extensions.sharedLibrary} -t $out/lib
      '';
    };

    test.script = ''
      zenroom -h | grep -q "Zenroom"
    '';
  };
}
