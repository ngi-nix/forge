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

  meta.description = "update Forge packages to the latest upstream version";
})
