{
  lib,
  pkgs,
  ...
}:

{
  packages.osadl-matrix = {
    version = "2024.05.23.010555";
    description = "OSADL license compatibility matrix as a CSV.";
    homePage = "https://github.com/priv-kweihmann/osadl-matrix";
    license = with lib.licenses; [
      cc-by-40
      unlicense
    ];

    source = {
      git = "github:priv-kweihmann/osadl-matrix/2024.05.23.010555";
      hash = "sha256-vcSaWDX8P07Bj035vGq5dZYO+WkZOod7tTubWygl27k=";
    };

    build.pythonPackageBuilder = {
      enable = true;

      packages = {
        build-system = with pkgs.python3Packages; [
          setuptools
        ];
        check = with pkgs.python3Packages; [
          pytestCheckHook
          requests
        ];
      };

      importsCheck = [
        "osadl_matrix"
      ];

      disabledTests = [
        # earlier in the tests, a full license db is cached and used, but these
        # require a different db afterward, but it's not loaded
        "test_compats"
        "test_supported_licenes_size"
        "test_supported_licenses"

        # requires internet access
        "test_license"
      ];
    };

    build.extraAttrs = {
      # Upstream setup.cfg has addopts, requiring pytest-{cov,forked,random-order}.
      # Clearing it is simpler than replicating those plugins, especially since
      # they only affect how tests run.
      pytestFlags = [
        "--override-ini=addopts="
      ];
    };
  };
}
