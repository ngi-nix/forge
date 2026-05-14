{
  packages.offen-script =
    {
      config,
      lib,
      pkgs,
      packages,
      ...
    }:

    {
      description = "Client-side analytics script for Offen.";
      inherit (packages.offen)
        source
        version
        homePage
        license
        ;

      build.pnpmPackageBuilder = {
        enable = true;
        pnpmDepsHash = "sha256-Vmv4aESpAvE9Dg28WpSPhtEEBr8q/BfqrJl5EXC0nl4=";
        sourceRoot = "source/script";
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
