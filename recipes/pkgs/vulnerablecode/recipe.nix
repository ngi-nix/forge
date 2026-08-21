{
  pkgs,
  lib,
  ...
}:
{
  pkgs.vulnerablecode = {
    version = "40.0.1";
    description = "A free and open vulnerabilities database and the packages they impact.";
    homePage = "https://public.vulnerablecode.io/";
    mainProgram = "vulnerablecode";
    license = lib.licenses.asl20;

    source = {
      git = "github:aboutcode-org/vulnerablecode/v${pkgs.vulnerablecode.version}";
      hash = "sha256-DoFkzzQpHhZBR80Dw58u9Pe7K+Iaas5rLPfSOb0o9fI="; # fill in after first build
    };

    build.pythonAppBuilder = {
      enable = true;

      # build-time dependencies
      packages.build = [
        pkgs.postgresql
        pkgs.libpq
      ];

      packages.build-system = with pkgs.python3Packages; [
        setuptools
        wheel
      ];

      packages.dependencies = with pkgs.python3Packages; [
        django
        toml
        requests
        markdown
        univers
        gitpython
        cvss
        lxml
        gunicorn
        texttable
        uritemplate
        dateutils
        dateparser
        crispy-bootstrap4
        drf-spectacular
        license-expression
        binaryornot
        saneyaml
        defusedxml
        packageurl-python
        beautifulsoup4
        extractcode
        psycopg2-binary
      ];

      relaxDeps = [
        "django"
        "requests"
        "markdown"
        "gitpython"
        "dateutils"
        "lxml"
        "gunicorn"
        "texttable"
        "license-expression"
        "crispy-bootstrap4"
        "beautifulsoup4"
        "python-dateutil"
        "defusedxml"
        "dateparser"
        "drf-spectacular"
        "extractcode"
        "psycopg2-binary"
      ];

      packages.run = [
      ];
    };
  };
}
