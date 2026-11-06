{
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
