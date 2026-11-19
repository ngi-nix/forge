{
  python3,
  gitMinimal,
  imagemagick,
  nix,
  nixfmt,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "forge-screenshots";
  version = "0.0.0";
  pyproject = true;

  src = ./.;

  build-system = with python3.pkgs; [
    setuptools
  ];

  dependencies = [
    gitMinimal
    imagemagick
    nix
    nixfmt
    python3.pkgs.nix-manipulator
  ];

  meta.description = "configure and update application screenshots";
})
