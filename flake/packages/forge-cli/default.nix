{
  python3,
  replaceVars,

  # Flake whose `packages.<system>.apps` the command runs, builds or evaluates:
  # the flake that imports the forge flake module (`self` of that flake).
  # In the forge repository, the same as `forge`.
  flake,
  # The NGI Forge flake (`forge-inputs.self`), for `lib.parametersFromStrings`
  # and `nixpkgs`, which the flake with the applications may not have.
  forge,
}:
let
  expr = replaceVars ./expr.nix {
    flakeSrc = flake.outPath;
    flakeNarHash = flake.narHash;
    forgeSrc = forge.outPath;
    forgeNarHash = forge.narHash;
    inherit (python3.stdenv.hostPlatform) system;
  };
in
python3.pkgs.buildPythonApplication {
  pname = "forge-cli";
  version = forge.shortRev or forge.dirtyShortRev or "unknown";
  pyproject = true;

  src = ./.;

  makeWrapperArgs = [
    "--set"
    "FORGE_EXPR"
    expr
  ];

  build-system = with python3.pkgs; [
    setuptools
  ];

  meta = {
    description = "Evaluate, build, run or enter a shell of a Forge application with its parameters set";
    mainProgram = "forge";
  };
}
