{
  lib,
  writeShellApplication,
  gitMinimal,
  nix,
  nixfmt,
  python3,
}:
writeShellApplication {
  name = "forge-screenshots";
  runtimeInputs = [
    gitMinimal
    nix
    nixfmt
    python3
  ];
  text =
    let
      # The script reads `eval.nix` from its directory.
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./eval.nix
          ./forge_screenshots.py
        ];
      };
    in
    ''
      exec python3 ${src}/forge_screenshots.py "$@"
    '';
  meta.description = "update application screenshots from AppStream metainfo, Flathub and URLs";
}
