{
  pkgs,
  ...
}:
{
  pkgs.librnd4 = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.callPackage ./_librnd4.nix { };
    };
  };
}
