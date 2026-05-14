{
  packages.offen-auditorium =
    {
      config,
      lib,
      pkgs,
      packages,
      ...
    }:

    {
      description = "Analytics UI for Offen.";
      inherit (packages.offen)
        source
        version
        homePage
        license
        ;

      build.pnpmPackageBuilder = {
        enable = true;
        pnpmDepsHash = "sha256-xpdFlgHBUcHgL16hruFg6Spv1IlBEc7PB/UqpKnv5Oo=";
        sourceRoot = "source/auditorium";
        buildScript = "build";
        installDir = "dist";
      };

      build.extraAttrs = {
        preBuild = ''
          cp -r ../locales locales
        '';
      };
    };
}
