{
  forge-lib,
  config,
  pkgs,
  ...
}:

let
  app = config.apps.zelph;
  usageSnippets = forge-lib.snippets.usage app;
in

{
  pkgs.zelph = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.callPackage ../../_nixpkgs/zelph { };
    };
  };

  pkgs.zelph-playground = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.zelph.playground;
    };
  };

  apps.zelph = {
    displayName = "Zelph";
    description = "Semantic network system and reasoning engine.";
    longDescription = ''
      Zelph is a
      [semantic network](https://en.wikipedia.org/wiki/Semantic_network) system and
      [reasoning engine](https://en.wikipedia.org/wiki/Semantic_reasoner).

      It treats logic, rules, and mathematics not as external code, but as
      [homoiconic structures](https://en.wikipedia.org/wiki/Homoiconicity)
      within the graph itself.
    '';

    usage = ''
      > [!NOTE]
      > You can try out Zelph in your browser without any installation through the [official playground](https://zelph.org/play) page.

      Before you start following the examples below, you should preferably have a look at the first few sections of the [Core Concepts](https://zelph.org/concepts/#the-self-fact-prefix) page to have a better understanding of what we'll be doing.

      You could also check out this [video presentation](https://zelph.org/presentation), which introduces the project and goes through some of its main concepts.

      ##### Simple Semantic Network

      In this example, we will define relationships between Nix-ecosystem components.

      First, ${usageSnippets.run-shell}.

      Then, start the `zelph` REPL:

      ```bash
      $ zelph
      zelph 1.0.1
      -- REPL mode - type .help for commands, e.g. '.help .deductions' to change what is shown --
      ```

      Next, let's define what the following terms are:

      ```bash
      zelph> Nix "is a" "Package Manager"
      zelph> Nixpkgs ~ "Repository"
      zelph> NixOS ~ "Operating System"
      ```

      Note that the `~` symbol is identical in function to `"is a"`.
      The only difference is that it's one of the [pre-defined core nodes](https://zelph.org/concepts/#predefined-core-nodes) that `zelph` offers, whereas `"is a"` is our [custom one](https://zelph.org/concepts/#working-with-custom-relations).

      Now that we know what things are, we will define some relations between them:

      ```bash
      zelph> Nixpkgs contains Nix
      zelph> NixOS "is built with" Nix
      ```

      > [!NOTE]
      > When relations contain spaces, they must be enclosed in quotation marks: `"`

      Then, we'll also define a [rule](https://zelph.org/rules/#rules-and-inference), which will be inferred by the `zelph` engine:

      ```bash
      zelph> (X "is built with" Y, Y "is a" Z) => (X uses Z)
      ```

      Rules are in the format of: `conditions => consequences`.
      So in this case, if the conditions are:

      1. `X "is built with" Y`
      1. `Y "is a" Z`

      Then the consequence is: `X uses Z`.

      After entering the rule in the REPL, the engine will apply it to nodes that satisfy its conditions and will return the following output:

      ```
      ((Y "is a" Z), (X "is built with" Y)) => (X uses Z)
      (NixOS uses "Package Manager") ⇐ {(Nix "is a" "Package Manager") (NixOS "is built with" Nix)}
      ```

      > [!NOTE]
      > By default, the inference engine is triggered after every rule or fact is entered, which can be toggled with the `.auto-run` command.
      > For more information, see the [Performing Inference](https://zelph.org/rules/#performing-inference) page.

      Finally, we can visualise all the nodes and the relationships between them through a mermaid graph:

      ```
      zelph> .mermaid
      Mermaid HTML: file:///tmp/«NixOS» «uses» «Package Manager».html
      ```

      ```bash
      open "/tmp/«NixOS» «uses» «Package Manager».html"
      ```

      ##### Wikidata

      In this example, we will be working with the dataset that contains P279 ("subclass of") statements of a Wikidata dump.

      > [!NOTE]
      > You will need at least 0.6 GiB of RAM to load the dataset.

      First, ${usageSnippets.run-shell}.

      Download the P279 data file:

      ```bash
      wget https://huggingface.co/datasets/acrion/zelph/resolve/d966f3bd7db4900479eaba2a97cabd056fc719a1/wikidata-20260309-all-pruned-small-P279.bin
      ```

      Then, start the `zelph` REPL and load it:

      ```bash
      $ zelph
      zelph> .load wikidata-20260309-all-pruned-small-P279.bin
      ```

      If you run `.stat`, you'll see network statistics like the number of nodes and the available [languages](https://zelph.org/quickstart/?h=language#languages-names):

      ```bash
      zelph-> .stat
      Network Statistics:
      ------------------------
      Nodes: 2005556
      RAM Usage: 0.6 GiB
      Name-of-Node Entries by language:
        wikidata: 890781
        en: 775631
      Node-of-Name Entries by language:
        wikidata: 890780
        en: 775631
      Languages: 2
      Rules: 0
      ------------------------
      ```

      Currently, we're in the special `zelph` language, but we can change this to either `wikidata` or `en`, which would allow us to work with Wikidata IDs and their English labels respectively.
      We will set it to `en`:

      ```bash
      zelph-> .lang en
      ```

      And then show details on a node by label:

      ```
      en-> .node program
      Resolved to node ID: 68336022
      Node ID: 68336022
        Variable: no
        Name in language 'wikidata': 'Q4303335'
        Name in language 'en': 'program'
        Wikidata URL: https://www.wikidata.org/wiki/Q4303335
        Mermaid HTML: file:///tmp/program.html
        Incoming connections from:
          - "Q4303335 - program" P279 "Q7397 - software" (ID 8106613304738465484)
        Outgoing connections to:
          - "Q40056 - computer program" P279 "Q4303335 - program" (ID 6787316433941954401)
          - "Q4303335 - program" P279 "Q7397 - software" (ID 8106613304738465484)
          - "Q1341685 - inference engine" P279 "Q4303335 - program" (ID 8949627094285483789)
        Representation: "Q4303335 - program"
      ------------------------
      ```

      This also shows the Wikidata ID of this node (Q4303335), which we can use to figure out its sub-classes:

      ```
      eng-> .lang wikidata
      wikidata-> X P279 Q4303335
      X P279 Q4303335
      Answer: Q40056 P279 Q4303335
      Answer: Q1341685 P279 Q4303335
      ```

      What we're querying here is essentially: all nodes (`X`) which are a subclass (`P279`) of node `Q4303335`.

      If you've noticed, these answers already exist in the `Outgoing connections to` the `program` node:

      ```
      wikidata> .lang en
      en-> .node program
        ...
        Outgoing connections to:
          - "Q40056 - computer program" P279 "Q4303335 - program" (ID 6787316433941954401)
          - "Q4303335 - program" P279 "Q7397 - software" (ID 8106613304738465484)
          - "Q1341685 - inference engine" P279 "Q4303335 - program" (ID 8949627094285483789)
        Representation: "Q4303335 - program"
      ------------------------
      ```

      This is just a small demonstration of what we can do with zelph.
      ${usageSnippets.see-docs}
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
