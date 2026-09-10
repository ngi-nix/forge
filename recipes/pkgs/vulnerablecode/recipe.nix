{
  pkgs,
  ...
}:
{
  pkgs.vulnerablecode.build.identityBuilder = {
    enable = true;
    derivation = pkgs.python3Packages.callPackage ./_vulnerablecode.nix { };
  };
}
