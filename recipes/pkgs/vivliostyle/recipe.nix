{
  nixpkgs,
  ...
}:
{
  # TODO: replace with Nixpkgs derivation when this PR propagates to the forge:
  # https://github.com/NixOS/nixpkgs/pull/544599
  pkgs.vivliostyle = nixpkgs.callPackage ./nixpkgs.txt { };
}
