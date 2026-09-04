{
  pkgs,
  ...
}:
{
  pkgs.pcb-rnd = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.callPackage ./_pcb-rnd.nix { };
    };
  };
}
