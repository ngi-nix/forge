{
  pkgs,
  ...
}:
{
  pkgs.sch-rnd = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.callPackage ./_sch-rnd.nix { };
    };
  };
}
