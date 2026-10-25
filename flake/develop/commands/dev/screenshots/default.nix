{
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
  text = ''
    exec python3 ${./forge_screenshots.py} "$@"
  '';
  meta.description = "update application screenshots from AppStream metainfo and Flathub";
}
