{
  config,
  pkgs,
  ...
}:

let
  app = config.apps.zelph;
in

{
  pkgs.zelph = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.callPackage ./_zelph.nix { };
    };
  };

  pkgs.zelph-playground = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.callPackage ./_zelph-playground.nix { };
    };
  };

  apps.zelph = {
    displayName = "Zelph";
    description = "Semantic network system and reasoning engine.";
    longDescription = ''
      zelph is a semantic network system and reasoning engine written in C++
      with an embedded Janet scripting layer.

      It treats logic, rules, and mathematics not as external code, but as
      [homoiconic structures](https://en.wikipedia.org/wiki/Homoiconicity) within the graph itself.

      By blending the flexibility of semantic webs (like Wikidata) with logic
      programming concepts (deep unification, constructive rules, negation as
      failure), zelph effectively transforms a static knowledge base into an
      executable graph.
    '';

    usage = ''
      You can try out Zelph in your browser without any installation through the [official playground](https://zelph.org/play) page.

      [Core Concepts](https://zelph.org/concepts/#the-self-fact-prefix) page.

      ##### Command Line

      First, [launch the shell environment](app/${app.name}#run-shell) containing `${app.name}`.

      ```bash
      -- Define Nix ecosystem relationships
      zelph> Nix "is a" "Package Manager"
      zelph> Nixpkgs "~" "Repository"
      zelph> Nixpkgs "contains" Nix
      zelph> NixOS "~" "Operating System"
      zelph> NixOS "is built with" Nix

      -- Define a rule: anything built with a package manager "uses" it
      zelph> (X "is built with" Y, Y "is a" Z) => (X "uses" Z)

      -- Trigger inference
      zelph> .run
      ```

      ##### Local Playground
    '';

    links = {
      website = "https://zelph.org";
      source = "https://github.com/acrion/zelph";
      docs = "https://zelph.org";
    };

    ngi.grants = {
      Commons = [
        "Zelph"
      ];
    };

    programs = {
      mainPackage = pkgs.zelph;
      packages = with pkgs; [
        zelph
        zelph-playground
      ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };
  };
}
