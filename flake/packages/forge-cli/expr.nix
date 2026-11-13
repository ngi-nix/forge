# Evaluated by `forge`, with the arguments from its command line.
# The arguments are passed only when an attribute is selected, hence `result`.
{
  # Application name.
  app,
  # Attribute path of the application output, for example `container`.
  output,
  # JSON object of the parameters, with string values.
  parameters,
}:
let
  # Locked flakes, so that they can be used in pure evaluation:
  # the flake with the applications, and `forge` for its library.
  flake = builtins.getFlake "path:@flakeSrc@?narHash=@flakeNarHash@";
  forge = builtins.getFlake "path:@forgeSrc@?narHash=@forgeNarHash@";
  inherit (forge.inputs.nixpkgs) lib;

  forgeApp = flake.packages."@system@".apps.${app} or (throw "There is no application `${app}`.");

  overridden = forgeApp.override (
    forge.lib.parametersFromStrings app forgeApp.config.parameters (lib.fromJSON parameters)
  );
in
{
  result =
    if output == "" then
      overridden
    else
      lib.attrByPath (lib.splitString "." output)
        (throw "The application `${app}` has no output `${output}`.")
        overridden;
}
