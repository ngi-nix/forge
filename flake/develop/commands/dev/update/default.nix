{
  lib,
  writeShellApplication,
  gitMinimal,
  nix-prefetch-git,
  nix,
  python3,
}:
let
  srcDir = toString ./.;
  pythonEnv = python3.withPackages (ps: [
    ps.colorama
  ]);
in
writeShellApplication {
  name = "forge-update";
  runtimeInputs = [
    gitMinimal
    nix-prefetch-git
    nix
    pythonEnv
  ];
  text = ''
    export PYTHONPATH="${srcDir}:''${PYTHONPATH-}"
    exec python3 -m forge_update "$@"
  '';
  meta.description = "Update forge package recipes to latest upstream versions";
}
