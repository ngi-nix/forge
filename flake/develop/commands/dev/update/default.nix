{
  lib,
  writers,
  writeShellApplication,
  gitMinimal,
  nix-prefetch-git,
  nix,
}:
let
  script = writers.writePython3Bin "forge-update" {
    libraries = [ ];
    flakeIgnore = [
      "E402"
      "E501"
    ];
  } (lib.readFile ./forge-update.py);
in
writeShellApplication {
  name = "forge-update";
  runtimeInputs = [
    gitMinimal
    nix-prefetch-git
    nix
  ];
  text = ''
    ${lib.getExe script} "$@"
  '';
  meta.description = "Update forge package recipes to latest upstream versions";
}
