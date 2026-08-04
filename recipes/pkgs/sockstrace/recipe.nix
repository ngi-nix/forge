{
  lib,
  pkgs,
  ...
}:
{
  pkgs.sockstrace = {
    version = "1.0.0";
    description = "Ptrace-based proxy leak detector that identifies network connections bypassing configured proxies.";
    homePage = "https://github.com/namecoin/sockstrace";
    mainProgram = "sockstrace";
    license = lib.licenses.gpl3Only;

    source = {
      git = "github:namecoin/sockstrace/v1";
      hash = "sha256-vUJSuazo5C23UacQGKxTXrLek6vEu9+S9PzfBjXa9Nc=";
      patches = [
        ./add-go-deps.patch
      ];
    };

    build.goPackageBuilder = {
      enable = true;
      packages.build = [
        pkgs.pkg-config
      ];
      packages.run = [
        pkgs.libseccomp
      ];
      vendorHash = "sha256-EFHYvWYXvpB6QMk345wUgcx54W1yWzXuphq+8oDiVzE=";
    };

    build.extraAttrs = {
      postInstall = ''
        mv $out/bin/main.go $out/bin/sockstrace
      '';
    };

    test = {
      packages = [
        pkgs.curl
        pkgs.cacert
      ];
      script = ''
        export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        sockstrace -horklump.program curl -horklump.args https://example.com
      '';
    };
  };
}
