{
  config,
  forge-inputs,
  lib,
  ...
}:
{
  imports = [
    (lib.modules.importApply ./builder.nix {
      name = "identity";
      imports = identity/options.nix;
      mkDerivation = mk: (mk { }).derivation;
      attrs = builder: finalAttrs: previousAttrs: {
        derivation = builder.derivation // {
          shellHook =
            builder.derivation.shellHook or ""
            + ''
              echo "ngi-forge: '${builder.derivation.pname}' is available at version '${builder.derivation.version}'."
            ''
            + lib.optionalString config.build.debug ''
              source ${forge-inputs.nix-utils}/nix-develop-interactive.bash
            '';
          forge = previousAttrs.passthru.forge;
        };
      };
      parentImports = [
        (
          {
            config,
            lib,
            ...
          }:
          {
            config =
              let
                builder = config.build.builders.identity;
                drv = builder.derivation;
              in
              lib.mkIf builder.enable {
                homePage = drv.meta.homepage;
                description = lib.mkDefault (lib.removeSuffix "." drv.meta.description + ".");
                inherit (drv) version;
                inherit (drv.meta)
                  license
                  ;
                broken = lib.mkDefault drv.meta.broken;
                unfree = lib.mkDefault drv.meta.unfree;
              };
          }
        )
      ];
    })
  ];
}
