{
  lib,
  python3,
  gitMinimal,
  nix,
}:

let
  runtimePath = lib.makeBinPath [
    gitMinimal
    nix
  ];
in

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "forge-update";
  version = "0.0.0";
  pyproject = true;

  src = ./.;

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    runtimePath
  ];

  build-system = with python3.pkgs; [
    setuptools
  ];

  dependencies = with python3.pkgs; [
    colorama
  ];

  optional-dependencies = {
    dev = with python3.pkgs; [
      pytest
      syrupy
    ];
  };

  pythonImportsCheck = [
    "forge_update"
  ];

  nativeCheckInputs =
    with python3.pkgs;
    [
      gitMinimal
      pytestCheckHook
    ]
    ++ lib.concatAttrValues finalAttrs.passthru.optional-dependencies;

  meta.description = "update Forge packages to the latest upstream version";
})
