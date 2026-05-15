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
        _forge-ui-dev = pkgs.callPackage packages/forge-ui-dev.nix {
          inherit (self'.packages)
            _forge-ui
            _forge-docs
            _forge-options
            ;
        };
      };
    };
}
