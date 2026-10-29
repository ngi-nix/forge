{
  lib,
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    (packageBuilderModule {
      name = "pnpmPackageBuilder";
      imports = ./options.nix;
      mkDerivation = pkgs.stdenvNoCC.mkDerivation;
      attrs =
        builder: finalAttrs: previousAttrs:
        {
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

          installPhase = lib.concatStringsSep "\n" [
            "runHook preInstall"
            (lib.optionalString (builder.installDir != null) "cp -r ${builder.installDir} $out")
            "runHook postInstall"
          ];
        }
        // lib.optionalAttrs (builder.sourceRoot != null) {
          inherit (builder) sourceRoot;
        };
    })
  ];
}
