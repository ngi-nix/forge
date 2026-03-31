# Usage:
#   nix-shell --run 'dev-ui-mock'
{
  replaceVarsWith,
  runtimeShell,
}:
(replaceVarsWith {
  name = "dev-ui-mock";
  isExecutable = true;
  dir = "bin";
  src = ../dev-ui/ui.sh;
  replacements = {
    inherit runtimeShell;
    defaultListenPort = 3000;
    mockBackend = "true";
  };
  meta.description = "UI dev script which launches with a mock backend";
})
