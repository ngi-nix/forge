{
  stdenv,
  fetchurl,
  lib,
  pkg-config,

  # software rendered gtk2
  withGtk2 ? false,
  gtk2,
  gdk-pixbuf,

  libGL,
  libGLU,

  # hardware accelerated gtk2
  withGtk2Gl ? false,
  gtkglext,

  # hardware accelerated gtk4
  withGtk4Gl ? false,
  gtk4,
  libepoxy,

  # motif gui support
  withMotif ? false,
  motif,
  libx11,
  libxt,
  libxinerama,
  libxrender,

  # support import and export of pixmap images
  withPixmap ? true,
  gd,

  # integrates remote, web access resources like edakrill or gedasymbols.org
  withCloud ? true,
  wget,
}:
let
  withGl = (withGtk2Gl || withGtk4Gl);
  withAnyGui = (withGtk2 || withGtk2Gl || withGtk4Gl || withMotif);
  coreFlags = [
    "--plugin-script"
    "--buildin-diag_rnd"
    "--buildin-lib_gensexpr"
    "--buildin-hid_batch"
    "--buildin-lib_portynet"
    "--buildin-lib_exp_text"
    "--buildin-remctrl_tcp"
    "--buildin-import_pixmap_pnm"
  ];

  gtk2Flags = [
    "--plugin-hid_gtk2_gdk"
  ];

  guiFlags = [
    "--plugin-irc"
    "--plugin-lib_hid_common"
  ];

  motifFlags = [
    "--plugin-hid_lesstif"
  ];

  gtkFlags = [
    "--plugin-lib_gtk2_common"
  ];

  pixmapFlags = [
    "--plugin-import_pixmap_gd"
    "--plugin-lib_exp_pixmap"
  ];

  gtk4GlFlags = [
    "--plugin-hid_gtk4_gl"
    "--plugin-lib_gtk4_common"
  ];

  cloudFlags = [
    "--plugin-lib_wget"
  ];

  gtk2GlFlags = [
    "--plugin-hid_gtk2_gl"
  ];

  glFlags = [
    "--plugin-lib_hid_gl"
  ];

in
stdenv.mkDerivation (finalAttrs: {
  pname = "librnd4";
  version = "4.5.0";

  src = fetchurl {
    url = "http://www.repo.hu/projects/librnd/releases/librnd-${finalAttrs.version}.tar.gz";
    hash = "sha256-qHhQq6MdSbMlSqf1qHhbmh5WcAp4XRI9/nvDeXZZCBw=";
  };

  sourceRoot = "librnd-${finalAttrs.version}";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs =
    lib.optionals withGtk2 [
      gtk2
      gdk-pixbuf
    ]
    ++ lib.optionals withGtk2Gl [
      gtk2
      gdk-pixbuf
      gtkglext
    ]
    ++ lib.optionals withGtk4Gl [
      gtk4
      libepoxy
    ]
    ++ lib.optionals withMotif [
      motif
      libx11
      libxt
      libxinerama
      libxrender
    ]
    ++ lib.optionals withGl [
      libGL
      libGLU
    ]
    ++ lib.optionals withPixmap [ gd ]
    ++ lib.optionals withCloud [ wget ];

  configureFlags = lib.unique (
    [
      "--all=disable"
    ]
    ++ coreFlags
    ++ lib.optionals withAnyGui guiFlags
    ++ lib.optionals withMotif motifFlags
    ++ lib.optionals withGtk2 (gtk2Flags ++ gtkFlags)
    ++ lib.optionals withGtk2Gl (gtk2GlFlags ++ gtkFlags ++ glFlags)
    ++ lib.optionals withGtk4Gl (gtk4GlFlags ++ glFlags)
    ++ lib.optionals withPixmap pixmapFlags
    ++ lib.optionals withCloud cloudFlags
  );

  doCheck = true;

  meta = {
    description = "Free/open source, flexible, modular two-dimensional CAD engine";
    homepage = "http://repo.hu/projects/librnd";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ AhmedAmr ];
    teams = with lib.teams; [ ngi ];
    platforms = lib.platforms.linux;
  };
})
