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

  # for exports like export_bom, export_dxf, export_gerber, etc.
  withExport ? true,
  gd,

  # for export_openems
  withExportSim ? true,

  # for import_ttf
  withGeoImports ? true,
  freetype,

  # for the netlist/schematic importers (import_edif, import_gnetlist, etc.)
  withImport ? true,

  # for the autorouter/autoplacer (autoroute, autoplace, import_mucs, etc.)
  withAuto ? true,

  # for lib_netmap (support lib for alien formats / io-standard / auto)
  withIoLib ? true,

  # for io_pcb, io_tedax (native pcb-rnd + tEDAx format support)
  withIoStandard ? true,

  # GUI flags
  withGtk2 ? true,
  withGtk2Gl ? true,
  withGtk4Gl ? true,
  withMotif ? true,

  # for io_kicad, io_eagle, etc.
  withAlienFormats ? true,
  libxml2,

  withCloud ? true, # for online footprint library fetching
  wget,

  # for extra exporters like export_stl, export_fidocadj, etc.
  withExtraExports ? true,

  # extra action commands (distalign, teardrops, renumber, etc.)
  withExtra ? true,

}:
let
  librnd4WithOptions = librnd4.override {
    inherit
      withGtk4Gl
      withMotif
      withGtk2
      withGtk2Gl
      withCloud
      ;
    withPixmap = withExport;
  };
  withAnyGui = (withGtk2 || withGtk2Gl || withGtk4Gl || withMotif);

  debugFlags = [
    "--plugin-diag"
  ];

  exportFlags = [
    "--plugin-cam"
    "--plugin-export_bom"
    "--plugin-export_dxf"
    "--plugin-export_excellon"
    "--plugin-export_gcode"
    "--plugin-export_gerber"
    "--plugin-export_hpgl"
    "--plugin-export_openscad"
    "--plugin-export_png"
    "--plugin-export_ps"
    "--plugin-export_stat"
    "--plugin-export_svg"
    "--plugin-export_web2"
    "--plugin-export_xy"
    "--plugin-millpath"
  ];

  exportSimFlags = [
    "--plugin-export_openems"
  ];

  importGeoFlags = [
    "--plugin-import_hpgl"
    "--plugin-import_ttf"
  ];

  importNetFlags = [
    "--plugin-import_accel_net"
    "--plugin-import_calay"
    "--plugin-import_edif"
    "--plugin-import_fpcb_nl"
    "--plugin-import_gnetlist"
    "--plugin-import_ipcd356"
    "--plugin-import_ltspice"
    "--plugin-import_mentor_sch"
    "--plugin-import_net_action"
    "--plugin-import_net_cmd"
    "--plugin-import_netlist"
    "--plugin-import_orcad_net"
    "--plugin-import_pads_net"
    "--plugin-import_protel_net"
    "--plugin-import_sch2"
    "--plugin-import_sch_rnd"
    "--plugin-import_tinycad"
  ];

  autoFlags = [
    "--plugin-ar_extern"
    "--plugin-asm"
    "--plugin-autoplace"
    "--plugin-autoroute"
    "--plugin-import_mucs"
    "--plugin-rbs_routing"
    "--plugin-smartdisperse"
  ];

  ioLibFlags = [
    "--plugin-lib_netmap"
  ];

  ioStandardFlags = [
    "--plugin-io_pcb"
    "--plugin-io_tedax"
  ];

  guiFlags = [
    "--plugin-dialogs"
    "--plugin-draw_fontsel"
    "--plugin-lib_hid_pcbui"
  ];

  coreFlags = [
    "--buildin-act_draw"
    "--buildin-act_read"
    "--buildin-autocrop"
    "--buildin-ch_editpoint"
    "--buildin-ch_onpoint"
    "--buildin-ddraft"
    "--buildin-draw_csect"
    "--buildin-draw_fab"
    "--buildin-draw_pnp"
    "--buildin-drc_query"
    "--buildin-extedit"
    "--buildin-exto_std"
    "--buildin-fp_board"
    "--buildin-fp_fs"
    "--buildin-io_lihata"
    "--buildin-lib_compat_help"
    "--buildin-lib_formula"
    "--buildin-lib_polyhelp"
    "--buildin-mincut"
    "--buildin-propedit"
    "--buildin-query"
    "--buildin-report"
    "--buildin-rubberband_orig"
    "--buildin-shape"
    "--buildin-show_netnames"
    "--buildin-suite"
    "--buildin-tool_std"
  ];

  alienFormatFlags = [
    "--plugin-io_autotrax"
    "--plugin-io_bxl"
    "--plugin-io_dsn"
    "--plugin-io_eagle"
    "--plugin-io_easyeda"
    "--plugin-io_hyp"
    "--plugin-io_kicad"
    "--plugin-io_kicad_legacy"
    "--plugin-io_pads"
  ];

  cloudFlags = [
    "--plugin-fp_wget"
    "--plugin-order"
    "--plugin-order_pcbway"
  ];

  exportExtraFlags = [
    "--plugin-export_fidocadj"
    "--plugin-export_ipcd356"
    "--plugin-export_lpr"
    "--plugin-export_oldconn"
    "--plugin-export_stl"
  ];

  extraFlags = [
    "--plugin-distalign"
    "--plugin-djopt"
    "--plugin-fontmode"
    "--plugin-jostle"
    "--plugin-polycombine"
    "--plugin-polystitch"
    "--plugin-puller"
    "--plugin-renumber"
    "--plugin-shand_cmd"
    "--plugin-teardrops"
    "--plugin-vendordrill"
  ];
in
stdenv.mkDerivation (finalAttrs: {
  version = "3.1.8";
  pname = "pcb-rnd";

  src = fetchurl {
    url = "http://www.repo.hu/projects/pcb-rnd/releases/pcb-rnd-${finalAttrs.version}.tar.gz";
    hash = "sha256-H83EgDGCL+Ole1c9psXGveaBmSxcfJxb41TmEDjCH+E=";
  };

  sourceRoot = "pcb-rnd-${finalAttrs.version}";
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
  ++ lib.optionals withExport [ gd ]
  ++ lib.optionals withGeoImports [ freetype ]
  ++ lib.optionals withCloud [ wget ]
  ++ lib.optionals (withAlienFormats || withCloud || withExtraExports) [ libxml2 ];

  configureFlags = lib.unique (
    [
      "--all=disable"
    ]
    ++ coreFlags
    ++ lib.optionals withDebug debugFlags
    ++ lib.optionals withExport exportFlags
    ++ lib.optionals withExportSim exportSimFlags
    ++ lib.optionals withGeoImports importGeoFlags
    ++ lib.optionals withImport importNetFlags
    ++ lib.optionals withAuto (autoFlags ++ ioLibFlags ++ ioStandardFlags)
    ++ lib.optionals withIoLib ioLibFlags
    ++ lib.optionals withIoStandard (ioStandardFlags ++ ioLibFlags)
    ++ lib.optionals withAnyGui guiFlags
    ++ lib.optionals withAlienFormats (alienFormatFlags ++ ioLibFlags ++ extraFlags)
    ++ lib.optionals withCloud (cloudFlags ++ exportFlags)
    ++ lib.optionals withExtraExports (exportExtraFlags ++ exportFlags)
    ++ lib.optionals withExtra extraFlags
  );

  preFixup = lib.optionalString (withCloud && withGtk4Gl) ''
    gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ wget ]})
  '';

  postFixup = lib.optionalString (withCloud && !withGtk4Gl) ''
    wrapProgram $out/bin/pcb-rnd --prefix PATH : ${lib.makeBinPath [ wget ]}
  '';

  meta = {
    description = "Free/open source, flexible, modular Printed Circuit Board editor";
    homepage = "http://repo.hu/projects/pcb-rnd";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ AhmedAmr ];
    teams = with lib.teams; [ ngi ];
    platforms = lib.platforms.linux;
    mainProgram = "pcb-rnd";
  };
})
