{
  pkgs,
  ...
}:
{
  apps.py3dtiles = {
    displayName = "Py3DTiles";
    description = "Python module and CLI to create 3DTiles from various 3D geo-referenced data types and formats.";
    usage = ''
      Py3DTiles provides a command-line interface and a Python module for creating 3DTiles from various 3D data formats (like point clouds and 3D models).

      You can use the CLI to convert your point clouds (XYZ, LAS, PLY) into 3DTiles:

      ```bash
      py3dtiles convert --out output_dir/ your_data.xyz
      ```

      Or you can use it to get information about an existing file:

      ```bash
      py3dtiles info your_data.pnts
      ```

      For Python scripts, this environment provides a python3 with the `py3dtiles` python package installed.
      You can import and use it seamlessly:

      ```python
      from py3dtiles.tileset.utils import number_of_points_in_tileset
      from pathlib import Path
      print(number_of_points_in_tileset(Path("output_dir/tileset.json")))
      ```
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Core = [ "Py3DTiles" ];
    };

    links = {
      website = "https://py3dtiles.org";
      docs = "https://py3dtiles.org/main";
      source = "https://gitlab.com/py3dtiles/py3dtiles";
    };

    programs = {
      packages = [
        pkgs.py3dtiles
        (pkgs.python3.withPackages (pp: [
          pp.py3dtiles
        ]))
      ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      export NUMBA_CACHE_DIR="$(mktemp -d)"

      cat <<EOF > test.xyz
      0 0 0
      1 1 1
      EOF

      set -x
      py3dtiles convert --out output test.xyz

      python -c '
      from py3dtiles.tileset.utils import number_of_points_in_tileset
      from pathlib import Path
      assert number_of_points_in_tileset(Path("output/tileset.json")) == 2
      '
      set +x
    '';
  };
}
