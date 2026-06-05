{
  pkgs,
  ...
}:

{
  apps.vg = {
    displayName = "Variation Graphs";
    description = "Tools for working with genome variation graphs.";
    usage = ''
      VG is a toolkit for working with genome variation graphs.
      It provides tools for mapping, calling, and manipulating variation graph representations of genomes.

      #### Examples

      The instructions below will use the `tiny` dataset of the [vg tests](https://github.com/vgteam/vg/tree/4cd46f212268f5d78a4dc42af22208e2be08d8a2/test), but feel free to experiment with other ones like `small` or `complex`.

      ##### Basic usage

      Construct a graph:

      ```bash
      vg construct -r tiny/x.fa -v tiny/x.vcf.gz > x.vg
      ```

      Index graph into a xg/gcsa pair:

      ```bash
      vg index -x x.xg -g x.gcsa -k 16 x.vg
      ```

      Convert graph to an image (e.g. using graphviz):

      ```bash
      vg view -d x.vg >x.dot
      dot -Tpng x.dot -o output.png
      ```

      For full documentation, please refer to the [project documentation](https://github.com/vgteam/vg#usage).
    '';

    ngi.grants = {
      Review = [ "VariationGraph" ];
    };

    links = {
      source = "https://github.com/vgteam/vg";
      website = "https://vgteam.github.io";
    };

    programs = {
      packages = with pkgs; [
        vg
      ];

      runtimes.shell = {
        enable = true;
      };
    };
  };
}
