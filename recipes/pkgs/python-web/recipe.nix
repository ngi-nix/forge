{
  lib,
  pkgs,
  ...
}:

{
  pkgs.python-web = {
    version = "0-unstable-2025-10-10";
    description = "Python web application example built from GitHub source.";
    homePage = "https://github.com/imincik/python-web-example";
    mainProgram = "python-web";
    license = lib.licenses.mit;

    source = {
      git = "github:imincik/python-web-example/14412a7b914561a8464428a34fb86aaa1e913f0c";
      hash = "sha256-jQAIaAzNjxgfIUS3kr99S54EokdT05YVZSaZTTSSmag=";
    };

    build.pythonAppBuilder = {
      enable = true;
      packages.build-system = [
        pkgs.python3Packages.setuptools
      ];
      packages.dependencies = [
        pkgs.python3Packages.flask
        pkgs.python3Packages.psycopg2
      ];
    };
  };
}
