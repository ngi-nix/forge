{
  pkgs,
  lib,
  ...
}:

{
  pkgs.docspec = {
    version = "1.21.11";
    description = "Document conversion SDK for rich text formats.";
    homePage = "https://github.com/docspec/docspec";
    mainProgram = "docspec";
    license = lib.licenses.eupl12;

    source = {
      git = "github:docspec/docspec/v1.21.11";
      hash = "sha256-FxVLfPpRIG+36I/veiGTO1fisSmIW/dcRi1WGEarEr0=";
      lfs = true; # test files (not big in size)
    };

    build = {
      builders.rust = {
        enable = true;
        cargoHash = "sha256-g3UvCPNNwnzwtEpRBgEM4u637hPligXc8r72oKe1XMQ=";
        packages.check = with pkgs; [
          # Required for health-check test, else it fails with:
          # No CA certificates were loaded from the system
          cacert
        ];
      };
    };

    test.script = ''
      echo '# Hello' \
        | docspec convert --from markdown --to blocknote \
        > blocknote.json

      for file in ${pkgs.docspec.src}/tests/fixtures/docx/pandoc/*.docx; do
        filename=$(basename $file)
        docspec convert $file --output ./''${filename%.*}.md
      done
    '';
  };
}
