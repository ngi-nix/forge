{
  lib,
  pkgs,
  ...
}:
{
  apps.bids = {
    displayName = "BIDS";
    description = "Analyse ELF binaries and search dependency information.";
    categories = with lib.categories; [ Development ];
    usage = ''
      BIDS (Binary Identification of Dependencies with Search) is a toolkit for
      analysing ELF binaries, generating Software Bill of Materials (SBOMs), and
      searching binary dependency and symbol information. It is intended for
      software analysis and vulnerability research, not malware detection.

      **Note:** Running the `bids` program directly starts the `bids-analyser`
      tool by default.

      Analyse an ELF binary and save the results to a JSON file:

      ```bash
      bids-analyser -f ./my-binary --output-file analysis.json
      ```

      Generate an SPDX SBOM from the analysis:

      ```bash
      sbom4bids -i analysis.json --output-file sbom.spdx
      ```

      Launch the text-based user interface:

      ```bash
      bids-ui
      ```

      To index a directory of analysis files and search for binaries containing a
      specific symbol:

      ```bash
      bids-search --initialise
      bids-search --index ./analysis-results
      bids-search --search "strcpy"
      ```
    '';
    links = {
      source = "https://github.com/APH10/BIDS";
    };

    ngi.grants = {
      Core = [
        "BIDS"
      ];
    };

    programs = {
      mainPackage = pkgs.bids;
      packages = [ pkgs.bids ];
      runtimes.shell.enable = true;
      runtimes.program.enable = true;
    };

    test.programs = {
      packages = [ pkgs.gcc ];
      script = ''
        cat > hello.c << 'EOF'
        #include <stdio.h>
        int main() {
          printf("Hello, world!\n");
          return 0;
        }
        EOF
        gcc hello.c -o hello
        mkdir analysis
        mkdir dataset
        bids-analyser -f ./hello --output-file analysis/analysis.json
        export BIDS_DATASET=dataset
        bids-search --initialise
        bids-search --index analysis
        bids-search --search "puts"
        rm -rf dataset
        rm -rf analysis
      '';
    };
  };
}
