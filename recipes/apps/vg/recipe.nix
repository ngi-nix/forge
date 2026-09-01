{
  config,
  pkgs,
  ...
}:

let
  app = config.apps.vg;
in

{
  pkgs.vg = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.vg;
    };
  };

  apps.vg = {
    displayName = "Variation Graphs";
    description = "Tools for working with genome variation graphs.";
    longDescription = ''
      VG is a toolkit for working with genome variation graphs.

      It provides tools for mapping, calling, and manipulating variation graph representations of genomes.
    '';
    usage = ''
      First, [launch the shell envrionment](app/${app.name}#run-shell) containing `${app.name}`.

      The instructions below will use the `tiny` dataset of the [vg tests](https://github.com/vgteam/vg/tree/${app.data.vgCommit.content}/test) directory.
      You can fetch them either by cloning the repository locally with git:

      ```bash
      git clone ${app.links.source}
      cd test
      ```

      or by using a tool like [degit](https://search.nixos.org/packages?channel=unstable&query=degit#show=degit) to only get the directories we need:

      ```bash
      degit vgteam/vg/test vg-tests
      cd vg-tests
      ```

      Feel free to experiment with other datasets like `small` or `complex`.

      ##### Visualising a genome strand

      First, construct a graph from the genome:

      ```bash
      vg construct -r tiny/tiny.fa -v tiny/tiny.vcf.gz > x.vg
      ```

      Next, index the graph into a xg/gcsa pair:

      ```bash
      vg index -x x.xg -g x.gcsa -k 16 x.vg
      ```

      Finally, convert the graph to an image (e.g. using graphviz):

      ```bash
      vg view -d x.vg >x.dot

      nix shell nixpkgs#graphviz -c dot -Tpng x.dot -o output.png
      ```

      For full documentation, please refer to the [project documentation](${app.links.docs}).
    '';

    data = {
      vgCommit = "4cd46f212268f5d78a4dc42af22208e2be08d8a2";
    };

    ngi.grants = {
      Review = [
        "VariationGraph"
      ];
    };

    links = {
      source = "https://github.com/vgteam/vg";
      website = "https://vgteam.github.io";
      docs = "https://github.com/vgteam/vg#usage";
    };

    programs = {
      mainPackage = pkgs.vg;
      packages = [ pkgs.vg ];

      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };
  };
}
