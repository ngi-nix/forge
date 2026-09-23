{
  pkgs,
  lib,
  config,
  ...
}:
let
  recipe = config.pkgs.labplot;
in
{
  pkgs.labplot = {
    version = "2.12.1";
    description = "Free, open-source, cross-platform data visualization and analysis software.";
    homePage = "https://labplot.kde.org";
    mainProgram = "labplot";
    license = lib.licenses.gpl2;

    source = {
      git = "git:https://invent.kde.org/education/labplot?tag=2.12.1";
      hash = "sha256-68ODqeOBp2tynFgLgk4e5AoVcZAwk27Vrggy493F9QU=";
    };

    build.standardBuilder = {
      enable = true;

      packages.build = with pkgs; [
        cmake
        pkg-config
        shared-mime-info
        bison
        kdePackages.extra-cmake-modules
        kdePackages.kdoctools
        kdePackages.knewstuff
        qt6.wrapQtAppsHook
      ];

      packages.run = with pkgs; [
        kdePackages.karchive
        kdePackages.kconfig
        kdePackages.kcrash
        kdePackages.kiconthemes
        kdePackages.kcoreaddons
        kdePackages.kcompletion
        kdePackages.ki18n
        kdePackages.ktextwidgets
        kdePackages.kwidgetsaddons
        kdePackages.kconfigwidgets
        kdePackages.kio
        kdePackages.kxmlgui
        kdePackages.kcolorscheme
        kdePackages.kparts
        kdePackages.kuserfeedback
        kdePackages.cantor
        kdePackages.purpose
        kdePackages.syntax-highlighting
        kdePackages.poppler

        gsl
        zlib
        boost
        cfitsio
        discount
        eigen
        fftw
        hdf5
        matio
        libcerf
        libixion
        liborcus
        lz4
        netcdf
        readstat
        zstd

        qt6.qtbase
        qt6.qtmqtt
        qt6.qtserialport
        qt6.qtsvg
        qt6Packages.qxlsx
      ];
    };

    build.extraAttrs = {
      cmakeFlags = [
        "-DENABLE_TESTS=OFF"
        "-DLOCAL_VECTOR_BLF=ON"
      ];

      patches = [
        # fixes build with qt6.10
        (pkgs.fetchpatch {
          url = "https://invent.kde.org/education/labplot/-/commit/b0e233b6b20134177af40e8904b593b8dbc18ada.patch";
          sha256 = "sha256-yl8T4u4byqPftAn6iPNdFUnxRDqp/sF864tUL19XdvU=";
        })
        # fixes a missing timer include in XYFourierFilterCurve.cpp
        (pkgs.fetchpatch {
          url = "https://invent.kde.org/education/labplot/-/commit/c2db2ec28aa8958f7041ae5cd03ddae9f44e5aa3.patch";
          sha256 = "sha256-0biKZXWMs5y1U9phAivEAbd2N4C/CiOKvk/QRAaPimo=";
        })
        # support liborcus-0.21
        (pkgs.fetchpatch {
          url = "https://invent.kde.org/education/labplot/-/commit/ee17e7659a97b36b58cab28b2b56cede7cd153c6.patch";
          sha256 = "sha256-NC5CjO4X27NGlt17CwcPNsLx4ClbpE1zacH/XGaWwTs=";
        })
      ];

      postFixup = ''
        wrapProgram $out/bin/labplot \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.pipewire ]}
      '';
    };

    test = {
      script = ''
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8
        labplot -platform offscreen --help-all | grep -q "LabPlot"
      '';
    };
  };
}
