{
  lib,
  ...
}:
{
  options = {
    usage = lib.mkOption {
      readOnly = true;
      type = lib.types.functionTo (lib.types.attrsOf lib.types.str);
      default = app: {
        run-program = "[launch the program](app/${app.name}#run-program)";
        run-shell = "[launch the shell environment](app/${app.name}#run-shell) containing `${app.name}`";
        run-container = "[launch the app in the container](app/${app.name}#run-container)";
        run-nixos = "[launch the app in the NixOS VM](app/${app.name}#run-nixos)";
        see-docs = "For more details and examples, please see the [project documentation](${
          lib.optionalString (app.links.docs != null) app.links.docs
        }) page.";
      };
      defaultText = lib.literalExpression ''
        app: {
          run-program = "[launch the program](app/''${app.name}#run-program)";
          run-shell = "[launch the shell environment](app/''${app.name}#run-shell) containing `''${app.name}`";
          run-container = "[launch the app in the container](app/''${app.name}#run-container)";
          run-nixos = "[launch the app in the NixOS VM](app/''${app.name}#run-nixos)";
          see-docs = "For more details and examples, please see the [project documentation](''${
            lib.optionalString (app.links.docs != null) app.links.docs
          }) page.";
        }
      '';
      description = "Re-usable application usage snippets in Markdown format.";
      example = lib.literalExpression ''
        {
          forgeConfig,
          ...
        }:

        let
          app = config.apps.my-app;
          usageSnippets = forgeConfig.forge.snippets.usage app;
        in

        {
          apps.my-app = {
            usage = '''
              First, ''${usageSnippets.run-shell}, then run the project executable.
            ''';
          };
        }
      '';
    };
  };
}
