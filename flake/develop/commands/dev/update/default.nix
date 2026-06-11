{
  lib,
  writers,
  writeShellApplication,
  gitMinimal,
  nix-prefetch-git,
  nix,
}:
let
  # Inject the store path of this directory so the script can locate the
  # sibling forge_update/ package at runtime.  We read + replace instead of
  # passing a path to writePython3Bin because the latter does not bundle
  # sub-directories alongside the resulting wrapper.
  srcDir = toString ./.;
  script = writers.writePython3Bin "forge-update" {
    libraries = [ ];
    flakeIgnore = [
      # sys.path.insert before import triggers "import not at top"
      "E402"
      # long replaceStrings line / error-message strings
      "E501"
    ];
  } (lib.replaceStrings [ "@forgeUpdateDir@" ] [ srcDir ] (lib.readFile ./forge-update.py));
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
