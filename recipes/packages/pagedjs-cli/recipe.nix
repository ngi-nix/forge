{
  config,
  pkgs,
  lib,
  ...
}:

{
  version = "0-main-2026-01-05";
  description = "Command line interface for Pagedjs PDF renderer.";
  homePage = "https://pagedjs.org";
  mainProgram = "pagedjs-cli";
  license = lib.licenses.mit;

  source = {
    git = "github:pagedjs/pagedjs-cli/1fc8c8956d665347a6a105c927be405a3ac462d6";
    hash = "sha256-393Q2B64lIPSYIckPOqVdhhQiHKcUE1jOpsYlFsiJvg=";
  };

  build.npmPackageBuilder = {
    enable = true;
    packages = {
      build = [
        pkgs.nodejs_22
        pkgs.makeWrapper
      ];
      run = [
        pkgs.chromium
      ];
    };
    npmDepsHash = "sha256-h3R+L9gROCqvKpzTg9woI0Om1J5Eo4NA1FCXjfnjwdU=";
    npmInstallFlags = [ "--ignore-scripts" ];
  };

  build.extraAttrs = {
    # Skip Puppeteer's Chrome download during dependency installation
    env.PUPPETEER_SKIP_DOWNLOAD = true;

    # Wrap the binary to set Chromium path
    # Launch browser with no sandboxing
    postInstall = ''
      mkdir -p $out/lib/node_modules/pagedjs-cli/docker-userdata

      wrapProgram $out/bin/pagedjs-cli \
        --set PUPPETEER_EXECUTABLE_PATH "${pkgs.chromium}/bin/chromium" \
        --add-flags "--browserArgs --no-sandbox"
    '';
  };

  test.script = ''
    pagedjs-cli --help | grep -q "Usage:"
  '';
}
