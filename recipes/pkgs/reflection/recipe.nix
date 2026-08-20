{
  pkgs,
  ...
}:
{
  pkgs.reflection.build.identityBuilder = {
    enable = true;
    # TODO: remove during next nixpkgs bump when this package is available from nixpkgs
    # https://github.com/NixOS/nixpkgs/pull/553858
    derivation = pkgs.callPackage ./_reflection.nix { };
  };
}
