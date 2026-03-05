{ ... }:
{
  perSystem =
    {
      config,
      lib,
      pkgs,
      system,
      ...
    }:

    {
      packages = {
        elm-watch = pkgs.callPackage packages/elm-watch.nix { };
      };
    };
}
