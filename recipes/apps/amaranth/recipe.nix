{
  lib,
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.amaranth;
in
{
  apps.amaranth = {
    displayName = "Amaranth HDL";
    description = "Amaranth is a hardware definition langauge for synchronous digital logic embedded within Python.";
    categories = with lib.categories; [ Development ];
    usage = ''
      Amaranth is a Python-based hardware description language and toolchain,
      covering the full FPGA development workflow: the HDL itself, a standard
      library of reusable digital design components, an event-driven simulator,
      and a build system that integrates with major FPGA toolchains.

      To view the full capabilities of Amaranth, see the [Docs](${recipe.links.docs}).

      This environment provides a Python with the `amaranth` package installed.
    '';

    links = {
      source = "https://github.com/amaranth-lang/amaranth";
      docs = "https://amaranth-lang.org/docs/amaranth";
    };

    ngi.grants = {
      Commons = [
        "Amaranth-HDL"
      ];
    };

    programs = {
      packages = [
        (pkgs.python3.withPackages (ps: [ ps.amaranth ]))
      ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      python -c '
      import amaranth; 
      assert(amaranth.__version__ == "${pkgs.python3Packages.amaranth.version}")
      '
    '';
  };
}
