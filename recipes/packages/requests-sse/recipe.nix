{
  config,
  pkgs,
  lib,
  ...

}:

{
  name = "requests-sse";
  version = "0.5.3";
  description = "Server-sent events python client library based on requests";
  license = lib.licenses.asl20;

  homePage = "https://github.com/overcat/requests-sse";

  source = {
    git = "github:overcat/requests-sse/0.5.3";
    hash = "sha256-+Zv7k+cYux7aBZk9MN7ySZh+pQUHNa6KjwxQ4l4aFxA=";
  };

  build.pythonPackageBuilder = {
    enable = true;
    packages = {
      build-system = [
        pkgs.python3Packages.poetry-core
      ];
      dependencies = [
        pkgs.python3Packages.requests
      ];
    };
    importsCheck = [ "requests_sse" ];
  };

  test.script = ''
    python -c "import requests_sse; print(requests_sse.__version__)"
  '';
}
