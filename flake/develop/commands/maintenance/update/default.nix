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

  # Allowlist the package's source files so Python test/type-checker caches
  # and other generated artifacts can never enter the store.
  pyAllowList = lib.sources.sourceByRegex ./. [
    "^(default\\.nix|pyproject\\.toml)$"
    "^forge_update(/[^/]+\\.py)?$"
    "^tests(/[^/]+\\.py)?$"
    "^tests/__snapshots__(/[^/]+\\.ambr)?$"
    "^tests/fixtures(/.*)?$"
  ];
in

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "forge-update";
  version = "0.0.0";
  pyproject = true;

  src = builtins.path {
    path = ./.;
    name = "forge-update-source";
    filter = pyAllowList.filter;
  };

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
