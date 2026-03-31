# Usage:
#   nix-shell --run 'dev-ui'
{
  replaceVarsWith,
  runtimeShell,
}:
(replaceVarsWith {
  name = "dev-ui";
  isExecutable = true;
  dir = "bin";
  src = ./ui.sh;
  replacements = {
    inherit runtimeShell;
    defaultListenPort = 3000;
    mockBackend = "false";
  };
  meta.description = "UI dev script";
})
