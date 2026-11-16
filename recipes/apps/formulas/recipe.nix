{
  config,
  forge-lib,
  lib,
  pkgs,
  ...
}:

let
  app = config.apps.formulas;
  usageSnippets = forge-lib.snippets.usage app;
  nixpkgsFormulas = pkgs.pkgsOriginal.python3.pkgs.formulas;
in

{
  pkgs.formulas = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.python3Packages.toPythonApplication pkgs.python3-formulas;
    };
  };

  pkgs.python3-formulas = {
    build.builders.identity = {
      enable = true;
      derivation =
        # TODO: Remove once https://github.com/NixOS/nixpkgs/pull/585711 is available in nixos-unstable
        if lib.elem pkgs.python3Packages.gunicorn (nixpkgsFormulas.dependencies or [ ]) then
          throw "PR #585711 landed for Formulas. The override in recipes/apps/formulas/recipe.nix should be removed."
        else
          nixpkgsFormulas.overridePythonAttrs (old: {
            dependencies = (old.dependencies or [ ]) ++ [ pkgs.python3Packages.gunicorn ];
            postPatch = (old.postPatch or "") + ''
              touch formulas/gui/__init__.py
              if grep -q "ctx.params\['app'\] = 'formulas.app:create_app'" formulas/cli.py; then
                substituteInPlace formulas/cli.py --replace-fail \
                  "ctx.params['app'] = 'formulas.app:create_app'" \
                  "ctx.params['app'] = 'formulas.app:create_app()'"
              fi
              substituteInPlace setup.py --replace-warn \
                "'formulas.gui': ['*']" \
                "'formulas.gui': ['templates/*']"
            '';
          });
    };
  };

  apps.formulas = {
    displayName = "Formulas";
    description = "High-performance Excel formulas interpreter and computation engine in Python.";
    longDescription = ''
      Formulas is an open-source computation engine that parses, compiles, and evaluates Excel formulas and workbooks in Python.

      It executes .xlsx and .ods spreadsheet models without requiring Microsoft Excel, transforming spreadsheet logic
      into reusable functions for data pipelines, automation workflows, and APIs.
    '';

    categories = with forge-lib.categories; [
      Office
      Spreadsheet
    ];

    data = {
      create-workbook = ./create_workbook.py;
      parse-formula = ./parse_formula.py;
      calculate-model = ./calculate_model.py;
    };

    usage = ''
      First, ${usageSnippets.run-shell}, which provides both the `formulas` CLI and a Python environment with `formulas` available.

      Create a sample Excel workbook (`workbook.xlsx`) by saving and running the following script:

      ```python file ${app.data.create-workbook.name}
      ${app.data.create-workbook}
      ```

      ```bash
      python ${app.data.create-workbook.name}
      ```

      ##### Command-line interface (CLI)

      Display the available commands:

      ```bash
      formulas --help
      ```

      Calculate formula values in the workbook:

      ```bash
      formulas calc workbook.xlsx --output-format json
      ```

      You can also overwrite input cells and render specific target cells:

      ```bash
      formulas calc workbook.xlsx \
        --overwrite "'[workbook.xlsx]SHEET1'!A1=5" \
        --render "'[workbook.xlsx]SHEET1'!B1=result" \
        --output-format json
      ```

      Export a portable JSON model from the workbook:

      ```bash
      formulas build workbook.xlsx --output-file model.json
      ```

      Start a local HTTP API server for the spreadsheet model:

      ```bash
      formulas serve workbook.xlsx --host 127.0.0.1 --port 5000
      ```

      ##### Python library usage

      You can also use Formulas programmatically in Python scripts:

      ###### Parsing and evaluating formulas

      ```python file ${app.data.parse-formula.name}
      ${app.data.parse-formula}
      ```

      ```bash
      python ${app.data.parse-formula.name}
      ```

      ###### Loading and calculating spreadsheet models

      ```python file ${app.data.calculate-model.name}
      ${app.data.calculate-model}
      ```

      ```bash
      python ${app.data.calculate-model.name}
      ```

      ${usageSnippets.see-docs}
    '';

    links = {
      website = "https://github.com/vinci1it2000/formulas";
      source = "https://github.com/vinci1it2000/formulas";
      docs = "https://formulas.readthedocs.io";
    };

    ngi.grants = {
      Commons = [
        "Formulas"
      ];
    };

    programs = {
      mainPackage = pkgs.formulas;
      packages = [
        pkgs.formulas
        (pkgs.python3.withPackages (ps: [
          pkgs.python3-formulas
        ]))
      ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };

    test.programs = {
      packages = [ pkgs.curl ];
      script = ''
        formulas --help | grep -q "Work with Excel and JSON spreadsheet models"

        python ${app.data.parse-formula.path}

        python ${app.data.create-workbook.path}
        test -f workbook.xlsx

        calc_json=$(formulas calc workbook.xlsx --output-format json)
        echo "$calc_json" | grep -q "'\[workbook.xlsx\]SHEET1'!B1\": 30"

        render_json=$(formulas calc workbook.xlsx \
          --overwrite "'[workbook.xlsx]SHEET1'!A1=5" \
          --render "'[workbook.xlsx]SHEET1'!B1=result" \
          --output-format json)
        echo "$render_json" | grep -q '"result": 25'

        formulas build workbook.xlsx --output-file model.json
        test -f model.json
        grep -q "'\[workbook.xlsx\]SHEET1'!B1" model.json

        python ${app.data.calculate-model.path}
        test -f output/WORKBOOK.XLSX

        formulas serve workbook.xlsx --host 127.0.0.1 --port 5000 &
        SERVE_PID=$!
        sleep 2
        curl --retry 5 --retry-connrefused -fs http://127.0.0.1:5000/api/health | grep -q '"status":"ok"'
        curl --retry 5 --retry-connrefused -fs http://127.0.0.1:5000/api/model | grep -q '"books":\["WORKBOOK.XLSX"\]'
        curl --retry 5 --retry-connrefused -fs http://127.0.0.1:5000/ | grep -q "Formulas Serve"
        kill $SERVE_PID 2>/dev/null || true
      '';
    };
  };
}
