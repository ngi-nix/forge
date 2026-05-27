{ inputs, ... }:
{
  perSystem =
    {
      self',
      config,
      lib,
      pkgs,
      system,
      ...
    }:

    {
      packages = {
        elm-watch = pkgs.callPackage packages/elm-watch.nix { };
        elm2nix = inputs.ngi-forge.inputs.elm2nix.packages.${system}.default;
      };
    };
}
