{
  forge-inputs,
  ...
}:
{
  config = {
    _module.args.packageBuilderModule =
      {
        mkDerivation,
        mkDerivationProvidesFinalAttrs ? true,
        name,
        imports ? { },
        attrs,
      }:
      {
        config,
        pkgs,
        lib,
        ...
      }@args:

      let
        builder = config.build.${name};
      in

      {
        options.build = lib.mkOption {
          type = lib.types.submoduleWith {
            modules = [
              ./env.nix
              ./structuredAttrs.nix
              ({ specialArgs, config, ... }: {
                options.${name} = lib.mkOption {
                  default = { };
                  type = lib.types.submoduleWith {
                    inherit specialArgs;
                    modules = [
                      imports
                      ./env.nix
                      ./structuredAttrs.nix
                      {
                        options.packages = {
                          build = lib.mkOption {
                            type = with lib.types; either (listOf package) (functionTo (listOf package));
                            default = [ ];
                            description = ''
                              List of build-time dependencies needed during compilation (native
                              architecture). Can be a list or a function `pkgs: [ ... ]`.

                              When defined as a function `pkgs: [ ... ]`, `pkgs` is the package's
                              effective Nixpkgs (respecting `nixpkgsPin` if specified).

                              Mapped to `nativeBuildInputs`.
                            '';
                            example = lib.literalExpression "pkgs: [ pkgs.cmake pkgs.pkg-config pkgs.ninja ]";
                          };
                          run = lib.mkOption {
                            type = with lib.types; either (listOf package) (functionTo (listOf package));
                            default = [ ];
                            description = ''
                              List of runtime dependencies needed by the package (target
                              architecture). Can be a list or a function `pkgs: [ ... ]`.

                              When defined as a function `pkgs: [ ... ]`, `pkgs` is the package's
                              effective Nixpkgs (respecting `nixpkgsPin` if specified).

                              Mapped to `buildInputs`.
                            '';
                            example = lib.literalExpression "pkgs: [ pkgs.openssl pkgs.sqlite pkgs.zlib ]";
                          };
                          check = lib.mkOption {
                            type = with lib.types; either (listOf package) (functionTo (listOf package));
                            default = [ ];
                            description = ''
                              List of test dependencies needed to run the test suite. Can be a list or a function `pkgs: [ ... ]`.

                              When defined as a function `pkgs: [ ... ]`, `pkgs` is the package's
                              effective Nixpkgs (respecting `nixpkgsPin` if specified).

                              Mapped to `nativeCheckInputs`.
                            '';
                            example = lib.literalExpression "pkgs: [ pkgs.cunit ]";
                          };
                        };
                      }
                    ];
                  };
                };
                config = lib.mkIf config.${name}.enable {
                  inherit (config.${name}) env structuredAttrs;
                };
              })
            ];
          };
        };

        config = lib.mkIf builder.enable {
          result.derivation =
            let
              mkSharedAttrs =
                finalAttrs:
                config.build.structuredAttrs
                // {
                  inherit (config)
                    pname
                    version
                    ;

                  src = import ./src.nix args;

                  inherit (config.source)
                    patches
                    ;

                  __structuredAttrs = true;
                  inherit (config.build) env;

                  nativeBuildInputs =
                    if lib.isFunction builder.packages.build then
                      builder.packages.build pkgs
                    else
                      builder.packages.build;
                  buildInputs =
                    if lib.isFunction builder.packages.run then builder.packages.run pkgs else builder.packages.run;
                  nativeCheckInputs =
                    if lib.isFunction builder.packages.check then
                      builder.packages.check pkgs
                    else
                      builder.packages.check;

                  passthru = {
                    test = config.test.derivation { inherit pkgs finalAttrs; };

                    env = pkgs.mkShell {
                      dontBuild = true;
                      phases = [ "installPhase" ];
                      installPhase = "touch $out";
                      env.ENV_PACKAGE_NAME = finalAttrs.pname;
                      env.ENV_PACKAGE_SOURCE = "${finalAttrs.src}";
                      inputsFrom = [
                        finalAttrs.finalPackage
                      ];
                      packages =
                        if lib.isFunction config.develop.packages then
                          config.develop.packages pkgs
                        else
                          config.develop.packages;
                      shellHook = config.develop.shellHook;
                    };

                    forge = {
                      broken = config.broken;
                    };
                  };

                  meta = {
                    inherit (config)
                      description
                      mainProgram
                      license
                      ;
                    homepage = config.homePage;
                  };
                }
                // {
                  shellHook = ''
                    echo "ngi-forge: '${finalAttrs.pname}' is available at version '${finalAttrs.version}'."
                  ''
                  + lib.optionalString config.build.debug ''
                    source ${forge-inputs.nix-utils}/nix-develop-interactive.bash
                  '';
                }
                //
                  # Warning(co-existence): `extraAttrs` is overridden by the builder's options.
                  # Eg. in `goPackageBuilder`, if `modRoot` is set in `extraAttrs.modRoot`
                  # instead of `build.goPackageBuilder.modRoot`,
                  # then `build.goPackageBuilder.modRoot`'s default
                  # will override `extraAttrs.modRoot`.
                  #
                  # This deprioritizing offen leads to a build failure
                  # which helps to spot lingering `build.extraAttrs`
                  # that must be converted once a proper option
                  # has been introduced (eg. to typecheck/merge them).
                  config.build.extraAttrs;

              mkDrvAttrs =
                finalAttrs:
                let
                  sharedAttrs = mkSharedAttrs finalAttrs;
                  builderAttrs = attrs builder finalAttrs sharedAttrs;
                in
                sharedAttrs // builderAttrs;
            in
            if mkDerivationProvidesFinalAttrs then
              mkDerivation mkDrvAttrs
            else
              let
                # Approximation for builder not yet providing `finalAttrs`
                # (eg. with `lib.extendMkDerivation`)
                finalAttrs = mkSharedAttrs finalAttrs // {
                  finalPackage = config.result.derivation;
                };
              in
              mkDerivation (mkDrvAttrs finalAttrs);
        };
      };
  };
}
