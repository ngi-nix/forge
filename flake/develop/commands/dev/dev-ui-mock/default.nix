# Usage:
#   nix-shell --run 'dev-ui-mock'
{
  callPackage,
}:
(callPackage ../dev-ui {
  mockBackend = "true";
  name = "dev-ui-mock";
  description = "UI dev script which launches with a mock backend";
})
