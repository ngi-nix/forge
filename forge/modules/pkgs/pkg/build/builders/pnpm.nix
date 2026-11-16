{
  bombon,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.modules.importApply ./builder.nix {
      name = "pnpm";
      imports = pnpm/options.nix;
      mkDerivation = pkgs.stdenvNoCC.mkDerivation;
      # `pnpm sbom` exists only from pnpm 11.
      passthruVendoredSbom =
        builder: drv:
        if lib.versionAtLeast builder.pnpm.version "11" then
          bombon.passthruVendoredSbom.pnpm drv { inherit pkgs; }
        else
          drv;
      attrs = builder: finalAttrs: previousAttrs: {
        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit (finalAttrs)
            pname
            src
            version
            sourceRoot
            ;
          inherit (builder) pnpm fetcherVersion;
          hash = builder.pnpmDepsHash;
        };
        nativeBuildInputs = previousAttrs.nativeBuildInputs or [ ] ++ [
          builder.pnpm
          pkgs.pnpmConfigHook
          pkgs.nodejs
        ];

        buildPhase = ''
          runHook preBuild
          pnpm run ${builder.buildScript}
          runHook postBuild
        '';

        installPhase = lib.optionalString (builder.installDir != null) "cp -r ${builder.installDir} $out";
      };
    })
  ];
}
