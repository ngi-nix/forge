{
  packageBuilderModule,
  forge-inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  builder = config.build.identityBuilder;
  resolvedDerivation =
    if builder.attribute != null then
      lib.getAttrFromPath (lib.splitString "." builder.attribute) (pkgs.pkgsOriginal or pkgs)
    else if lib.isFunction builder.derivation then
      builder.derivation pkgs
    else
      builder.derivation;
in
{
  imports = [
    (packageBuilderModule {
      name = "identityBuilder";
      imports = ./options.nix;
      mkDerivation = mk: (mk { }).derivation;
      attrs = builder: finalAttrs: previousAttrs: {
        derivation = resolvedDerivation // {
          shellHook =
            resolvedDerivation.shellHook or ""
            + ''
              echo "ngi-forge: '${resolvedDerivation.pname or config.pname}' is available at version '${
                resolvedDerivation.version or config.version
              }'."
            ''
            + lib.optionalString config.build.debug ''
              source ${forge-inputs.nix-utils}/nix-develop-interactive.bash
            '';
        };
      };
    })
    (
      {
        config,
        lib,
        ...
      }:
      {
        config =
          let
            drv = resolvedDerivation;
          in
          lib.mkIf builder.enable {
            homePage = drv.meta.homepage or "";
            description = lib.mkDefault (lib.removeSuffix "." (drv.meta.description or "") + ".");
            inherit (drv) version;
            inherit (drv.meta)
              license
              ;
          };
      }
    )
  ];
}
