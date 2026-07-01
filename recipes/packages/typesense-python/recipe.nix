{
  config,
  lib,
  pkgs,
  ...
}:

{
  packages.typesense-python = {
    version = "2.0.0";
    description = "Python client for Typesense, an open source and typo tolerant search engine.";
    homePage = "https://github.com/typesense/typesense-python";
    license = lib.licenses.asl20;

    source = {
      git = "github:typesense/typesense-python/v2.0.0";
      hash = "sha256-GzapEl26FS6yMGeLC54y9ysl0mt9l6ceYHr84E6BqBo=";
      patches = [
        ./0001-linux-only-metrics.patch
        ./0002-generated-temp-path.patch
        ./0003-tests-fix-endpoint-path.patch
        ./0004-tests-fix-rule_id.patch
        ./0005-test-gate-v30-collection-schema-expectations.patch
        ./0006-feat-curation-add-types-for-stem-and-synonyms-for-Ty.patch
      ];
    };

    build.pythonPackageBuilder = {
      enable = true;
      packages = {
        build-system = [
          pkgs.python3Packages.setuptools
        ];
        dependencies = [
          pkgs.python3Packages.requests
          pkgs.python3Packages.httpx
          pkgs.python3Packages.typing-extensions
        ];
      };
      importsCheck = [ "typesense" ];
      disabledTests = [ "import_typing_extensions" ];
    };

    build.extraAttrs = {
      nativeCheckInputs = with pkgs.python3Packages; [
        pkgs.curl
        pkgs.typesense
        pytestCheckHook
        faker
        httpx
        isort
        pytest-asyncio
        pytest-httpx
        pytest-mock
        python-dotenv
        requests-mock
        respx
      ];
      disabledTestMarks = [ "open_ai" ];

      preCheck = ''
        TYPESENSE_API_KEY="xyz" \
        TYPESENSE_DATA_DIR="$(mktemp -d)" \
        typesense-server &

        typesense_pid=$!

        # wait for typesense to finish starting.
        timeout 20 bash -c '
          while ! curl -s --fail localhost:8108/health; do sleep 1; done
        ' || false
      '';
      postCheck = ''
        kill $typesense_pid
      '';
    };
  };
}
