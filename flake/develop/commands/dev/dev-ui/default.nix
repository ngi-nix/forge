# Usage:
#   nix-shell --run 'dev-ui'
{
  replaceVarsWith,
  writeShellApplication,

  coreutils,
  gitMinimal,
  python3,
  runtimeShell,
  systemd,

  mockBackend ? "false",
  defaultListenPort ? 3000,
  numApps ? 5000,
  name ? "dev-ui",
  description ? "UI dev script",
}:
let
  substitutedScript = replaceVarsWith {
    name = "dev-ui-inner";
    isExecutable = true;
    dir = "bin";
    src = ./ui.sh;
    replacements = {
      inherit
        runtimeShell
        mockBackend
        defaultListenPort
        numApps
        ;
    };
  };
in
writeShellApplication {
  inherit name;
  runtimeInputs = [
    coreutils
    gitMinimal
    python3
    systemd
  ];
  text = ''
    exec ${substitutedScript}/bin/dev-ui-inner "$@"
  '';
  meta = { inherit description; };
}
