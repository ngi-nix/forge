{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  setuptools,
  wheel,
  django,
  toml,
  requests,
  markdown,
  univers,
  gitpython,
  cvss,
  python-dotenv,
  lxml,
  gunicorn,
  texttable,
  uritemplate,
  dateutils,
  dateparser,
  crispy-bootstrap4,
  drf-spectacular,
  license-expression,
  binaryornot,
  saneyaml,
  defusedxml,
  packageurl-python,
  beautifulsoup4,
  extractcode,
  psycopg2-binary,
  rq-scheduler,
  postgresql,
  libpq,
  callPackage,
}:

let
  cwe2 = callPackage ./_cwe2.nix { };
  fetchcode = callPackage ./_fetchcode.nix { };
  aboutcode-pipeline = callPackage ./_aboutcode-pipeline.nix { };
  aboutcode-federated = callPackage ./_aboutcode-federated.nix { };
in
buildPythonApplication (finalAttrs: {
  pname = "vulnerablecode";
  version = "40.0.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "aboutcode-org";
    repo = "vulnerablecode";
    tag = "v${finalAttrs.version}";
    hash = "sha256-DoFkzzQpHhZBR80Dw58u9Pe7K+Iaas5rLPfSOb0o9fI=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    django
    toml
    requests
    markdown
    univers
    gitpython
    cvss
    python-dotenv
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
    rq-scheduler
    cwe2
    fetchcode
    aboutcode-pipeline
    aboutcode-federated
  ];

  buildInputs = [
    postgresql
    libpq
  ];

  pythonRelaxDeps = [
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
    "python-dotenv"
    "drf-spectacular"
    "extractcode"
    "psycopg2-binary"
    "rq-scheduler"
  ];

  pythonImportsCheck = [
    "vulnerablecode"
  ];

  meta = {
    description = "Free and open vulnerabilities database and the packages they impact";
    homepage = "https://public.vulnerablecode.io/";
    mainProgram = "vulnerablecode";
    license = lib.licenses.asl20;
  };
})
