{
  lib,
  buildPythonPackage,
  fetchPypi,
  callPackage,
  packageurl-python,
  requests,
  saneyaml,
  uritemplate,
}:
let
  flot = callPackage ./_flot.nix { };
in
buildPythonPackage (finalAttrs: {
  pname = "aboutcode.federated";
  version = "1.0.3";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) version;
    pname = "aboutcode_federated";
    hash = "sha256-gWyusYZIvBGwhPoTCha7ap9ZC0szyM7ebIbQiJILRLc=";
  };

  build-system = [
    flot
  ];

  buildInputs = [
    requests
    uritemplate
    saneyaml
    packageurl-python
  ];

  pythonRelaxDeps = [ "requests" ];

  pythonImportsCheck = [
    "aboutcode.federated"
  ];

  meta = {
    description = "Federated data utilities";
    homepage = "https://github.com/aboutcode-org/aboutcode.federated";
    changelog = "https://github.com/aboutcode-org/aboutcode.federated/blob/${finalAttrs.src.rev}/CHANGELOG.rst";
    license = lib.licenses.asl20;
  };
})
