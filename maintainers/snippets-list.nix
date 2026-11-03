# Re-usable snippets in Markdown format.

{ lib }:

{
  # Application usage snippets.
  #
  # Example:
  #
  #   let
  #     app = config.apps.my-app;
  #     usageSnippets = lib.snippets.usage app;
  #   in
  #   {
  #     apps.my-app.usage = ''
  #       First, ${usageSnippets.run-shell}, then run the project executable.
  #     '';
  #   }
  usage = app: {
    run-program = "[launch the program](app/${app.name}#run-program)";
    run-shell = "[launch the shell environment](app/${app.name}#run-shell) containing `${app.name}`";
    run-container = "[launch the app in the container](app/${app.name}#run-container)";
    run-nixos = "[launch the app in the NixOS VM](app/${app.name}#run-nixos)";
    see-docs = "For more details and examples, please see the [project documentation](${
      lib.optionalString (app.links.docs != null) app.links.docs
    }) page.";
  };
}
