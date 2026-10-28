{
  config,
  pkgs,
  lib,
  packageBuilderModule,
  ...
}:
let
  stdenv =
    if lib.isFunction config.build.standardBuilder.stdenv then
      config.build.standardBuilder.stdenv pkgs
    else
      config.build.standardBuilder.stdenv;
in
{
  imports = [
    (packageBuilderModule {
      name = "standardBuilder";
      imports = ./options.nix;
      mkDerivation = stdenv.mkDerivation;
      attrs =
        builder: finalAttrs: previousAttrs:
        { };
    })
  ];
}
