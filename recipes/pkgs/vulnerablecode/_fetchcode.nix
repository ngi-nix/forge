{
  lib,
  fetchFromGitHub,

  buildPythonApplication,
  setuptools,
  setuptools-scm,
  wheel,
  attrs,
  commoncode,
  htmllistparse,
  packageurl-python,
  requests,
  python-dateutil,
  python-dotenv,
}:

buildPythonApplication (finalAttrs: {
  pname = "fetchcode";
  version = "0.8.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "aboutcode-org";
    repo = "fetchcode";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OkhL+zkkzVlW67k/dvHujdvDJJhJJ/Bx+X+Etr6OUFc=";
  };

  build-system = [
    setuptools
    setuptools-scm
    wheel
  ];

  dependencies = [
    attrs
    commoncode
    htmllistparse
    packageurl-python
    requests
    python-dateutil
    python-dotenv
  ];

  dontConfigure = true;

  pythonImportsCheck = [
    "fetchcode"
  ];

  meta = {
    description = "A library to reliably fetch code via HTTP, FTP and version control systems. This project is sponsored by NLnet project https://nlnet.nl/project/vulnerabilitydatabase/ Google Summer of Code, nexB and others generous sponsors";
    homepage = "https://github.com/aboutcode-org/fetchcode";
    changelog = "https://github.com/aboutcode-org/fetchcode/blob/${finalAttrs.src.rev}/CHANGELOG.rst";
    license = lib.licenses.unfree; # FIXME: nix-init did not find a license
    maintainers = with lib.maintainers; [ ];
    mainProgram = "fetchcode";
  };
})
