{
  python3,
  replaceVars,
  stdenvNoCC,

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
    inherit (stdenvNoCC.hostPlatform) system;
  };
in
stdenvNoCC.mkDerivation {
  pname = "forge";
  version = forge.shortRev or forge.dirtyShortRev or "unknown";

  src = ./forge.py;
  dontUnpack = true;

  # For `patchShebangs` to use it.
  buildInputs = [ python3 ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/forge
    substituteInPlace $out/bin/forge --replace-fail @expr@ ${expr}
    runHook postInstall
  '';

  meta = {
    description = "Run, build, evaluate or enter a shell of an application with its parameters set";
    mainProgram = "forge";
  };
}
