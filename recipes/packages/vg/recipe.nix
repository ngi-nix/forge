{
  lib,
  pkgs,
  packages,
  ...
}:

let
  customPython = pkgs.python3.withPackages (ps: [ ps.pybind11 ]);
in

{
  packages.vg = {
    version = "1.74.0";
    description = "Tools for working with genome variation graphs.";
    homePage = "https://github.com/vgteam/vg";
    mainProgram = "vg";
    license = lib.licenses.mit;

    source = {
      git = "github:vgteam/vg/v${packages.vg.version}";
      hash = "sha256-22Q7CZ4GncCaiuJHZk9vUlVf+0Q4Mrf+esD70OLNk3I=";
      submodules = true;
    };

    build.standardBuilder = {
      enable = true;
      packages.build = with pkgs; [
        autoconf
        automake
        bison
        cmake
        customPython
        flex
        gettext
        hostname
        libtool
        perl
        pkg-config
        which
        whoami
        util-linux # rev, and possibly others
      ];
      packages.run = with pkgs; [
        boost
        bzip2
        cairo
        curl
        expat
        jansson
        ncurses
        openssl
        protobuf
        xz
        zlib
        zstd
        libxdmcp
      ];
    };

    build.extraAttrs = {
      dontUseCmake = true; # cmake needed for deps, but not main package
      dontConfigure = true;
      enableParallelBuilding = true;

      __structuredAttrs = true;
      strictDeps = true;

      # needed, else build fails
      env.VG_GIT_VERSION = packages.vg.version;

      # deps/elfutils
      NIX_CFLAGS_COMPILE = toString [
        "-Wno-error=stringop-overflow"
        "-Wno-error=unterminated-string-initialization"
      ];

      makeFlags = [
        # don't build statically
        "START_STATIC="
        "END_STATIC="
      ];

      postPatch = ''
        substituteInPlace \
          Makefile \
            --replace-fail "/bin/bash" "${pkgs.stdenv.shell}" \
            --replace-fail "\$(shell arch)" "${pkgs.stdenv.hostPlatform.uname.processor}" \
            --replace-fail "vg_git_version.hpp]" "vg_git_version.hpp ]"

        substituteInPlace \
          deps/libbdsg/bdsg/deps/pybind11/tests/CMakeLists.txt \
          deps/vcflib/CMakeLists.txt \
            --replace-fail \
              "find_package(pybind11 " \
              "set(PYBIND11_FINDPYTHON ON)
              find_package(pybind11 "

        patchShebangs ./
        patchShebangs deps/

        patch -p1 -d deps/libbdsg -i ${./0001-Use-order-only-prerequisite-for-making-sure-dirs-exi.patch}

        pushd deps/htslib
          PACKAGE_VERSION=$(./version.sh)
          echo '#define HTSCODECS_VERSION_TEXT "$PACKAGE_VERSION"' > ./htscodecs/htscodecs/version.h
        popd
      '';

      preBuild = ''
        # Install directories may not exist when parallel builds complete their
        # output steps, so we create them here to prevent build failures.
        mkdir -p lib include obj/{pic/algorithms,algorithms,config,io,subcommand,unittest/support}
      '';

      # no install target
      installPhase = ''
        runHook preInstall

        mkdir -p $out/{bin,lib}

        cp bin/* $out/bin/
        cp -R lib/lib{handlegraph,vgio,hts,deflate}.so* $out/lib/

        runHook postInstall
      '';

      fixupPhase = ''
        runHook preFixup

        for bin in $out/bin/* ; do
          patchelf --allowed-rpath-prefixes /nix/store --shrink-rpath $bin
          patchelf --set-rpath "$out/lib:$(patchelf --print-rpath $bin)" $bin
        done

        # remove debugging symbols that make the binary bloated in size
        strip -d $out/bin/vg

        runHook postFixup
      '';
    };

    test.script = ''
      # build graph
      vg construct \
        -r ${pkgs.vg.src}/test/tiny/tiny.fa \
        -v ${pkgs.vg.src}/test/tiny/tiny.vcf.gz \
        >x.vg
    '';
  };
}
