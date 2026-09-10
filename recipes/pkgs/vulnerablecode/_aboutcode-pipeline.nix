{
  buildPythonPackage,
  fetchPypi,
  lib,
  callPackage,
}:
let
  flot = callPackage ./_flot.nix { };
in
buildPythonPackage (finalAttrs: {
  pname = "aboutcode.pipeline";
  version = "0.1.0";
  src = fetchPypi {
    inherit (finalAttrs) version;
    pname = "aboutcode_pipeline";
    hash = "sha256-1pF9Vrtc8BpibPUNCnma7fiir/Fnl03kshkOSTyOenY=";
  };

  build-system = [
    flot
  ];

  pyproject = true;

  pythonImportsCheck = [
    "aboutcode.pipeline"
  ];

  meta = {
    description = "Define and run pipelines.";
    homepage = "https://github.com/aboutcode-org/scancode.io/tree/main/aboutcode/pipeline";
    license = lib.licenses.asl20;
  };
})
