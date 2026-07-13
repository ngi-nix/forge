{
  flake.templates = rec {
    consumer = {
      path = ../templates/consumer;
      description = "Template for using and extending an NGI Forge instance";
    };
    provider = {
      path = ../templates/provider;
      description = "Template for self hosting your own NGI Forge instance";
      welcomeText = ''
        # NGI Forge provider template

        ## Content

        - `flake.nix`: main configuration file
        - `recipes`: example packages and apps
        - `maintainers/maintainer-list.nix`: maintainers list

        ## Quick Start

        - Add all files to Git

        ```
        git init && git add *
        ```

        - Build and run the Forge UI

        ```
        nix build .#_forge.ui
        nix run nixpkgs#python3 -- -m http.server -d ./result
        ```
      '';
    };
    examples = provider;
  };
}
