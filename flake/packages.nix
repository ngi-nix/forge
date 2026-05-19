{ ... }:
{
  perSystem =
    {
      self',
      config,
      lib,
      pkgs,
      system,
      inputs',
      ...
    }:

    {
      packages = {
        elm-watch = pkgs.callPackage packages/elm-watch.nix { };
        elm2nix = inputs'.elm2nix.packages.default;
        # highlight-js = pkgs.callPackage packages/highlight-js.nix { };
      };
    };
}
