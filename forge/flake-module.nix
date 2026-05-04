{
  self,
  config,
  ...
}:
let
  # This module is imported both in ngi-forge's `flake.nix`
  # and in users' `flake.nix` when they want to make a forge
  # based on ngi-forge's module system.
  # It currently is a flake-parts module.
  #
  # Warning(compatibility): `inputs.ngi-forge` (resp. `inputs.ngi-forge.inputs`)
  # must usually be used instead of `self` (resp. `inputs`)
  # everywhere inside this `flakeModule`.
  # Because when imported in some user's `flake.nix`,
  # the `self` (resp. `inputs`) given to this `flakeModule`
  # will no longer be the ngi-forge's `self` (resp. `inputs`) in scope right here.
  # For `inputs` to be available in `submodule`s and remain usable in `imports`
  # (without causing an infinite recursion by depending on `config._module.args`),
  # `specialArgs` must be threaded down `submodule`s by using `lib.types.submoduleWith`.
  flakeModule = {
    imports = [
      modules/forge.nix
      modules/apps/default.nix
      modules/packages.nix
      ./packages.nix
    ];
  };
in
{
  imports = [ flakeModule ];

  config = {
    # Usual flake-parts export interface for users to extend ngi-forge.
    flake.flakeModule = self.flakeModules.default;
    flake.flakeModules.default = self.flakeModules.ngi-forge;
    flake.flakeModules.ngi-forge = flakeModule;

    # Export the configuration to users who want to import ngi-forge's recipes
    # in order to let them extend or `mkOverride` them.
    #
    # Remark(clarity): this currently raise a warning in `nix flake check`:
    # > warning: unknown flake output 'flakeConfig'
    # Issue: https://github.com/NixOS/nix/issues/6381
    flake.flakeConfig = config;
  };
}
