{
  lib,
  packages,
  ...
}:

{
  packages.mox = {
    version = "0.0.15";
    description = "Modern full-featured open source secure mail server for low-maintenance self-hosted email.";
    homePage = "https://github.com/mjl-/mox";
    mainProgram = "mox";
    license = lib.licenses.mit;

    source = {
      git = "github:mjl-/mox/v${packages.mox.version}";
      hash = "sha256-apIV+nClXTUbmCssnvgG9UwpTNTHTe6FgLCxp14/s0A=";
      patches = [
        ./version.patch
      ];
    };

    build.goPackageBuilder = {
      enable = true;
      vendorHash = null;
      ldflags = [
        "-s"
        "-w"
        "-X github.com/mjl-/mox/moxvar.Version=${packages.mox.version}"
        "-X github.com/mjl-/mox/moxvar.VersionBare=${packages.mox.version}"
      ];
    };

    test.script = ''
      mox version | grep "${packages.mox.version}"
    '';
  };
}
