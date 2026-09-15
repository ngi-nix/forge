{
  lib,
  python,
  fetchFromGitHub,
}:

python.pkgs.buildPythonApplication (finalAttrs: {
  pname = "cwe2";
  version = "3.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "aboutcode-org";
    repo = "cwe2";
    tag = "v${finalAttrs.version}";
    hash = "sha256-IXtbhEpJMN4d1G5V9GvzU50yn69j0ygbWBYN6YOM8h4=";
  };

  build-system = [
    python.pkgs.setuptools
    python.pkgs.setuptools-scm
    python.pkgs.wheel
  ];

  dontConfigure = true;

  dependencies = with python.pkgs; [
    importlib-resources
    zipp
  ];

  pythonImportsCheck = [
    "cwe2"
  ];

  meta = {
    description = "Common weakness enumeration library for Python (maintained fork of https://github.com/Julian-Nash/cwe";
    homepage = "https://github.com/aboutcode-org/cwe2";
    changelog = "https://github.com/aboutcode-org/cwe2/blob/${finalAttrs.src.rev}/CHANGELOG.rst";
    license = lib.licenses.AND [
      lib.licenses.mit
      lib.licenses.unfreeRedistributable
    ];
    maintainers = with lib.maintainers; [ ];
    mainProgram = "cwe2";
  };
})
