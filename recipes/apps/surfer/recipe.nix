{
  lib,
  pkgs,
  ...
}:

{
  apps.surfer = {
    displayName = "Surfer Waveform Viewer";
    description = "A waveform viewer with a focus on a snappy usable interface, and extensibility.";
    categories = with lib.categories; [ Utility ];
    usage = ''
      Surfer is a waveform viewer for VCD, FST, and GHW files, with a focus on a
      snappy, extensible interface.

      Open a waveform file

      ```bash
      surfer waveform.vcd
      ```

      Surfer can also run in client-server mode, where the server (`surver`) is
      started with one or more waveform files, and the viewer connects to it
      remotely instead of opening the files directly

      ```bash
      surver waveform.vcd
      ```

      Once started, `surver` prints a local URL in its logs (for example
      `http://127.0.0.1:8911/abcxyz`). Pass this URL to `surfer` to connect to
      the running server

      ```bash
      surfer http://127.0.0.1:8911/abcxyz
      ```

      For remote access, set up an SSH tunnel to the `surver` port before
      connecting.
    '';

    ngi.grants = {
      Core = [
        "Surfer"
      ];
    };

    links = {
      website = "https://surfer-project.org";
      source = "https://gitlab.com/surfer-project/surfer";
      docs = "https://docs.surfer-project.org";
    };

    programs = {
      mainPackage = pkgs.surfer;
      packages = [ pkgs.surfer ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      surfer --version | grep ${pkgs.surfer.version}
      surver --version | grep ${pkgs.surfer.version}
    '';
  };
}
