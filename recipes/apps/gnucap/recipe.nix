{
  pkgs,
  ...
}:

{
  apps.gnucap = {
    displayName = "Gnucap";
    description = "GNU Circuit Analysis Package.";
    usage = ''
      Gnucap is a general purpose circuit simulator that performs DC, transient,
      and AC analyses, and supports Spice-compatible netlists.

      Start the interactive Gnucap shell

      ```bash
      gnucap
      ```

      Run a simulation from a netlist file

      ```bash
      gnucap -b circuit.ckt
      ```
    '';

    icon = ./icon.svg;

    links = {
      website = "http://www.gnucap.org/";
      docs = "https://www.gnu.org/software/gnucap/gnucap-man.pdf";
      source = "https://codeberg.org/gnucap/gnucap";
    };

    ngi.grants = {
      Commons = [
        "Gnucap-performance"
      ];
      Entrust = [
        "Gnucap-MixedSignals"
        "Gnucap-VerilogAMS"
      ];
    };

    programs = {
      packages = [
        pkgs.gnucap
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      cat <<EOF > circuit.ckt
      * Simple resistor circuit
      V1 1 0 DC 5
      R1 1 0 1k
      .DC V1 5 5 1
      .print DC V(1)
      .end
      EOF
      gnucap -b circuit.ckt | grep -q "5"
    '';
  };
}
