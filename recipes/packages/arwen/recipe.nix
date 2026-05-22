{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "arwen";
  version = "0.0.5-unstable-2026-04-07";
  description = "Cross-platform patching of shared libraries in Rust.";
  homePage = "https://github.com/nichmor/arwen";
  mainProgram = "arwen";
  license = lib.licenses.mit;

  source = {
    git = "github:nichmor/arwen/696351a8c208315b0dfd4a1e5c37288a689ccd2e";
    hash = "sha256-6RW8BeKjoxeO8SBz/VdZGnrRW+EIKq5NtrFdM0lx0+o=";
  };

  build.rustPackageBuilder = {
    enable = true;
    cargoHash = "sha256-bj7YB7xNlfdrYYZv3CDuqkm+/pg+C1KwizPTlNqQWt8=";
  };

  test.script = ''
    arwen elf print-rpath "${pkgs.hello}/bin/hello" | grep "glibc"
    arwen elf print-needed "${pkgs.hello}/bin/hello" | grep "libc"
  '';
}
