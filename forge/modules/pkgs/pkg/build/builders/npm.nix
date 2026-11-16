{
  bombon,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.modules.importApply ./builder.nix {
      name = "npm";
      imports = npm/options.nix;
      mkDerivation = pkgs.buildNpmPackage;
      passthruVendoredSbom =
        builder: drv:
        if builder.vendoredSbom then bombon.passthruVendoredSbom.npm drv { inherit pkgs; } else drv;
      attrs = builder: finalAttrs: previousAttrs: {
        nativeBuildInputs = previousAttrs.nativeBuildInputs or [ ] ++ [
          pkgs.nodejs
        ];
        inherit (builder)
          dontNpmBuild
          npmDepsHash
          npmFlags
          npmInstallFlags
          ;
      };
    })
  ];
}
