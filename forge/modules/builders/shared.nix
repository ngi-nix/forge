{
  forge-inputs,
  lib,
  pkgs,
  ...
}:
{
  config = {
    _module.args.packageBuilderModule =
      {
        mkDerivation,
        mkDerivationProvidesFinalAttrs ? true,
        builderName,
        attrs,
      }:
      { config, ... }:
      {
        options.build.${builderName} = {
          packages = {
            build = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = ''
                List of build-time dependencies needed during compilation (native
                architecture).

                Mapped to `nativeBuildInputs`.
              '';
              example = lib.literalExpression "[ pkgs.cmake pkgs.pkg-config pkgs.ninja ]";
            };
            run = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = ''
                List of runtime dependencies needed by the package (target
                architecture).

                Mapped to `buildInputs`.
              '';
              example = lib.literalExpression "[ pkgs.openssl pkgs.sqlite pkgs.zlib ]";
            };
            check = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = ''
                List of test dependencies needed to run the test suite.

                Mapped to `nativeCheckInputs`.
              '';
              example = lib.literalExpression "[ pkgs.cunit ]";
            };
          };
          env = lib.mkOption {
            description = ''
              Exported environment variables specific to the builder.
            '';
            default = { };
            apply = lib.filterAttrs (k: v: v != null);
            type = lib.types.submodule {
              freeformType =
                with lib.types;
                attrsOf (
                  nullOr (oneOf [
                    package
                    str
                    bool
                    int
                  ])
                );
            };
          };
          attrs = lib.mkOption {
            description = ''
              Attributes local to the buildscript and specific to the ${builderName} builder.
            '';
            default = { };
            apply = lib.filterAttrs (k: v: v != null);
            type = lib.types.submodule {
              freeformType =
                with lib.types;
                attrsOf (
                  nullOr (oneOf [
                    package
                    str
                    bool
                    int
                  ])
                );
            };
          };
        };
        config =
          let
            builder = config.build.${builderName};
          in
          lib.mkIf builder.enable {
            build.env = builder.env;
            build.attrs = builder.attrs;
            result.derivation =
              let
                initAttrs =
                  finalAttrs:
                  config.build.attrs
                  // {
                    inherit (config) pname version;
                    src =
                      let
                        fetchers = {
                          path = pkg: pkg.source.path;

                          git =
                            let
                              forges = {
                                # forge = fetchFunction
                                codeberg = pkgs.fetchFromCodeberg;
                                forgejo = pkgs.fetchFromForgejo;
                                gitea = pkgs.fetchFromGitea;
                                github = pkgs.fetchFromGitHub;
                                gitlab = pkgs.fetchFromGitLab;
                              };

                              gitSchemas = lib.fix (self: {
                                "3" = [
                                  "owner"
                                  "repo"
                                  "rev"
                                ];

                                "4" = [ "domain" ] ++ self."3";
                              });
                            in
                            pkg:
                            let
                              # Expected formats:
                              # - "forge:owner/repo/rev"
                              # - "forge:domain/owner/repo/rev"
                              parts = lib.splitString ":" pkg.source.git;
                              forge = lib.elemAt parts 0;
                              rest = lib.concatStringsSep ":" (lib.tail parts);
                            in
                            if forge == "git" then
                              let
                                # Split "https://host/path?key=value" into url and query
                                urlParts = lib.splitString "?" rest;
                                url = lib.elemAt urlParts 0;
                                queryAttrs =
                                  let
                                    # Parse key-value pairs into an attrset:
                                    #   "key1=value1&key2=value2" -> { key1 = value; key2 = value2; }
                                    parseQuery =
                                      query:
                                      lib.listToAttrs (
                                        map (
                                          param:
                                          let
                                            kv = lib.splitString "=" param;
                                          in
                                          lib.nameValuePair (lib.elemAt kv 0) (lib.elemAt kv 1)
                                        ) (lib.splitString "&" query)
                                      );
                                  in
                                  if lib.length urlParts > 1 then parseQuery (lib.elemAt urlParts 1) else { };
                              in
                              pkgs.fetchgit (
                                lib.recursiveUpdate queryAttrs {
                                  inherit url;
                                  hash = pkg.source.hash;
                                  fetchSubmodules = pkg.source.submodules;
                                }
                              )
                            else
                              let
                                pathParts = lib.splitString "/" rest;
                                schema = gitSchemas.${toString (lib.length pathParts)};

                                # assign each source attribute to its appropriate path part
                                sourceAttrs = lib.listToAttrs (lib.zipListsWith lib.nameValuePair schema pathParts);
                              in
                              forges.${forge} (
                                lib.recursiveUpdate sourceAttrs {
                                  hash = pkg.source.hash;
                                  fetchSubmodules = pkg.source.submodules;
                                }
                              );

                          url =
                            pkg:
                            pkgs.fetchurl {
                              url = pkg.source.url;
                              hash = pkg.source.hash;
                            };
                        };

                        # Determine which source type is used
                        sourceType =
                          pkg:
                          if pkg.source.path != null then
                            "path"
                          else if pkg.source.git != null then
                            "git"
                          else
                            "url";
                      in
                      fetchers.${sourceType config} config;

                    inherit (config.source) patches;
                    nativeBuildInputs = builder.packages.build;
                    buildInputs = builder.packages.run;
                    nativeCheckInputs = builder.packages.check;

                    __structuredAttrs = true;
                    inherit (config.build) env;

                    dontUnpack = !config.phases.unpack.enable;
                    preUnpack = config.phases.unpack.preScript;
                    postUnpack = config.phases.unpack.postScript;

                    dontPatch = !config.phases.patch.enable;
                    prePatch = config.phases.patch.preScript;
                    postPatch = config.phases.patch.postScript;

                    dontConfigure = !config.phases.configure.enable;
                    preConfigure = config.phases.configure.preScript;
                    postConfigure = config.phases.configure.postScript;

                    dontBuild = !config.phases.build.enable;
                    preBuild = config.phases.build.preScript;
                    postBuild = config.phases.build.postScript;

                    dontInstall = !config.phases.install.enable;
                    preInstall = config.phases.install.preScript;
                    postInstall = config.phases.install.postScript;

                    doCheck = config.phases.check.enable;
                    preCheck = config.phases.check.preScript;
                    postCheck = config.phases.check.postScript;

                    passthru = {
                      test = pkgs.testers.runCommand {
                        name = "${finalAttrs.pname}-test";
                        buildInputs = [ finalAttrs.finalPackage ] ++ config.test.packages;
                        script = config.test.script + "\ntouch $out";
                      };

                      env = pkgs.mkShell {
                        dontBuild = true;
                        phases = [ "installPhase" ];
                        installPhase = "touch $out";
                        env.ENV_PACKAGE_NAME = finalAttrs.pname;
                        env.ENV_PACKAGE_SOURCE = "${finalAttrs.src}";
                        inputsFrom = [
                          finalAttrs.finalPackage
                        ];
                        packages = config.develop.packages;
                        shellHook = config.develop.shellHook;
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
                  // lib.optionalAttrs config.build.debug {
                    shellHook = "source ${forge-inputs.inputs.nix-utils}/nix-develop-interactive.bash";
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
                mkAttrs =
                  finalAttrs:
                  let
                    init = initAttrs finalAttrs;
                  in
                  init // attrs builder finalAttrs init;
              in
              if mkDerivationProvidesFinalAttrs then
                mkDerivation (mkAttrs)
              else
                let
                  # Approximation for builder not yet providing `finalAttrs`
                  # (eg. with `lib.extendMkDerivation`)
                  finalAttrs = initAttrs finalAttrs // {
                    finalPackage = config.result.derivation;
                  };
                in
                mkDerivation (mkAttrs finalAttrs);
          };
      };
  };
}
