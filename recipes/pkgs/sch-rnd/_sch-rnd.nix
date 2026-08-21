{
  stdenv,
  fetchurl,
  lib,
  pkg-config,
  librnd4,
  makeWrapper,
  wrapGAppsHook4,

  # diagnostics/debug plugin
  withDebug ? false,

  # for exporting and exeucting SPICE
  withExportSim ? true,

  # for loading and saving boards in formats by other EDA tools
  withAlienFormats ? true,
  libxml2,

  # for exporting bitmap images
  withPngExport ? true,

  # GUI flags
  withGtk2 ? true,
  withGtk2Gl ? true,
  withGtk4Gl ? true,
  withMotif ? true,

  # for exporting vector image formats like SVG, PS, etc.
  withVectorExport ? true,

  # for extra export formats
  withExtraExports ? true,
}:
let
  librnd4WithOptions = librnd4.override {
    inherit
      withGtk4Gl
      withMotif
      withGtk2
      withGtk2Gl
      ;
    withPixmap = withPngExport;
    withCloud = false;
  };
  withAnyGui = (withGtk2 || withGtk2Gl || withGtk4Gl || withMotif);

  simFlags = [
    "--plugin-sim"
    "--plugin-sim_gui"
    "--plugin-sim_ngspice"
  ];

  alienFormatFlags = [
    "--plugin-export_accel"
    "--plugin-export_allegro"
    "--plugin-export_bae"
    "--plugin-export_cadstar"
    "--plugin-export_calay"
    "--plugin-export_eagle"
    "--plugin-export_eagle5"
    "--plugin-export_easyeda"
    "--plugin-export_edif"
    "--plugin-export_ewnet"
    "--plugin-export_fritzing"
    "--plugin-export_futurenet2"
    "--plugin-export_jsonnet"
    "--plugin-export_kicad"
    "--plugin-export_maxascii"
    "--plugin-export_orcad"
    "--plugin-export_osmond"
    "--plugin-export_pads_ascii"
    "--plugin-export_protelII"
    "--plugin-export_redac"
    "--plugin-export_systemc"
    "--plugin-export_tango"
    "--plugin-export_tinycad"
    "--plugin-export_xmlnet"
    "--plugin-io_altium"
    "--plugin-io_bxl"
    "--plugin-io_easyeda"
    "--plugin-io_eeschema"
    "--plugin-io_geda"
    "--plugin-io_orcad"
    "--plugin-io_tinycad"
    "--plugin-lib_alien"
    "--plugin-lib_ucdf"
  ];

  pngExportFlags = [
    "--plugin-export_png"
  ];

  guiFlags = [
    "--plugin-extobj_chart"
    "--plugin-gui"
    "--plugin-lib_plot"
    "--plugin-sch_dialogs"
  ];

  coreFlags = [
    "--buildin-act_draw"
    "--buildin-act_read"
    "--buildin-backann"
    "--buildin-construct"
    "--buildin-export_boxsym"
    "--buildin-export_spice"
    "--buildin-export_tedax"
    "--buildin-funcmap"
    "--buildin-hlibrary_fs"
    "--buildin-io_lihata"
    "--buildin-io_ngrp_fawk"
    "--buildin-io_ngrp_tedax"
    "--buildin-lib_anymap"
    "--buildin-lib_attbl"
    "--buildin-lib_nanojson"
    "--buildin-lib_netlist_exp"
    "--buildin-lib_ngrp"
    "--buildin-lib_target"
    "--buildin-lib_tedax"
    "--buildin-place"
    "--buildin-propedit"
    "--buildin-query"
    "--buildin-renumber"
    "--buildin-std_cschem"
    "--buildin-std_devmap"
    "--buildin-std_forge"
    "--buildin-std_tools"
    "--buildin-suite"
    "--buildin-symlib_fs"
    "--buildin-symlib_local"
    "--buildin-target_none"
    "--buildin-target_pcb"
    "--buildin-target_spice"
  ];

  vectorExportFlags = [
    "--plugin-export_ps"
    "--plugin-export_svg"
    "--plugin-export_tedax_footprint"
    "--plugin-export_web2"
  ];

  debugFlags = [
    "--plugin-diag"
  ];

  extraExportFlags = [
    "--plugin-attbl_csv"
    "--plugin-attbl_json"
    "--plugin-attbl_lht"
    "--plugin-attbl_tedax"
    "--plugin-export_abst"
    "--plugin-export_bom"
    "--plugin-export_lpr"
  ];

in
stdenv.mkDerivation (finalAttrs: {
  version = "1.0.11";
  pname = "sch-rnd";

  src = fetchurl {
    url = "http://www.repo.hu/projects/sch-rnd/releases/sch-rnd-${finalAttrs.version}.tar.gz";
    hash = "sha256-wQeRdGGM8qBSygdi5uy9c1ObLvulqKqews3N4CKQk/0=";
  };

  sourceRoot = "sch-rnd-${finalAttrs.version}";

  preConfigure = ''
    export LIBRND_PREFIX=${librnd4WithOptions}
  '';

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ]
  ++ lib.optionals withGtk4Gl [
    wrapGAppsHook4
  ];

  buildInputs = [
    librnd4WithOptions
  ]
  ++ lib.optionals withAlienFormats [ libxml2 ];

  configureFlags = lib.unique (
    [
      "--all=disable"
    ]
    ++ coreFlags
    ++ lib.optionals withExportSim (simFlags ++ guiFlags)
    ++ lib.optionals withAlienFormats alienFormatFlags
    ++ lib.optionals withPngExport pngExportFlags
    ++ lib.optionals withAnyGui guiFlags
    ++ lib.optionals withVectorExport vectorExportFlags
    ++ lib.optionals withDebug debugFlags
    ++ lib.optionals withExtraExports (extraExportFlags ++ vectorExportFlags)
  );

  meta = {
    description = "Simple, modular, scriptable schematics editor";
    homepage = "http://repo.hu/projects/sch-rnd";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ AhmedAmr ];
    teams = with lib.teams; [ ngi ];
    platforms = lib.platforms.linux;
    mainProgram = "sch-rnd";
  };
})
