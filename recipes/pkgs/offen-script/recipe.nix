{
  config,
  ...
}:

{
  pkgs.offen-script = {
    description = "Client-side analytics script for Offen.";
    inherit (config.pkgs.offen)
      source
      version
      homePage
      license
      ;

    build.pnpmPackageBuilder = {
      enable = true;
      pnpmDepsHash = "sha256-Vmv4aESpAvE9Dg28WpSPhtEEBr8q/BfqrJl5EXC0nl4=";
      buildScript = "build";
      installDir = "dist";
    };

    phases = {
      unpack.sourceRoot = "source/script";
      build.script.pre = ''
        cp -r ../locales locales
      '';
    };
  };
}
