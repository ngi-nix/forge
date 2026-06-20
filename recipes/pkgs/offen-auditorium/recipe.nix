{
  config,
  ...
}:

{
  pkgs.offen-auditorium = {
    description = "Analytics UI for Offen.";
    inherit (config.pkgs.offen)
      source
      version
      homePage
      license
      ;

    build.pnpmPackageBuilder = {
      enable = true;
      pnpmDepsHash = "sha256-xpdFlgHBUcHgL16hruFg6Spv1IlBEc7PB/UqpKnv5Oo=";
      buildScript = "build";
      installDir = "dist";
    };

    phases = {
      unpack.sourceRoot = "source/auditorium";
      build.script.pre = ''
        cp -r ../locales locales
      '';
    };
  };
}
