{
  buildPythonPackage,
  fetchPypi,
  lib,
}:
buildPythonPackage (finalAttrs: {
  pname = "flot";
  version = "0.7.3";
  format = "wheel";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    hash = "sha256-uGSxlKD+iJPux/5ixrBvTJiNoL35O0L+UityiynKNb8=";
  };

  meta = {
    description = "Make it easier to create Python packages. Build multiple Python packages from one repo easily.";
    homepage = "https://github.com/aboutcode-org/flot";
    license = lib.licenses.AND [
      lib.licenses.bsd2
      lib.licenses.bsd3
    ];
  };
})
