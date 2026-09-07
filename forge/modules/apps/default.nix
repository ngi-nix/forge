{
  config,
  lib,
  forge-lib,
  pkgs,
  ...
}:
let
  getEndNodes =
    tree:
    let
      go =
        id: curr:
        if builtins.elem "description" (builtins.attrNames curr) then
          {
            ${lib.lists.last id} = {
              pos = id;
              val = curr;
            };
          }
        else
          lib.foldlAttrs (
            acc: name: value:
            lib.recursiveUpdate acc (go (id ++ [ name ]) value)
          ) { } curr;
    in
    go [ ] tree;

  treeNode =
    appData:
    lib.mkOptionType {
      name = "treeNode";
      description = "tree node with leaves ${
        lib.optionDescriptionPhrase (class: class == "noun" || class == "composite") appData
      }";
      descriptionClass = "conjunction"; # treeNode OR appData
      check = val: builtins.isAttrs val;
      merge =
        loc: defs:
        let
          go =
            id: currentLevel:
            lib.trace id (
              if builtins.all (v: builtins.hasAttr "description" v.value) currentLevel then
                appData.merge id currentLevel
              else if builtins.any (v: builtins.hasAttr "description" v.value) currentLevel then
                abort "appData and not attrset of treenodes on same level"
              else
                let
                  attrNamesToLookAt = builtins.foldl' (
                    names: curr: # names :: Attrset ( null ), curr :: Attrset
                    names
                    // (builtins.foldl' (acc: elem: acc // { ${elem} = null; }) { } (builtins.attrNames curr.value))
                  ) { } currentLevel;
                  attrNamesWithNodes = builtins.mapAttrs (
                    name: _v: builtins.filter (node: builtins.elem name (builtins.attrNames node.value)) currentLevel
                  ) attrNamesToLookAt;
                  attrNamesApplied = builtins.mapAttrs (
                    name: value:
                    go (id ++ [ name ]) (
                      map (n: {
                        value = n.value.${name};
                        inherit (n) file;
                      }) value
                    )
                  ) attrNamesWithNodes;
                in
                attrNamesApplied
            );
        in
        go loc defs;
      getSubModules = appData.getSubModules;
      substSubModules = m: treeNode (appData.substSubModules m);
      emptyValue = {
        value = { };
      };
      /*
        functor = (lib.types.defaultFunctor "treeNode") // {
          payload = { inherit appData; };
            binOp = a: b:
              let merged = a.appData.typeMerge b.appData.functor;
              in if merged == null then null else { appData = merged; };
          binOp = abort "oh no";
          type = { appData }: treeNode appData;
        };
      */
    };
in
{
  options.forge = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        (
          { specialArgs, ... }@forgeArgs:
          {
            config = {
              # Convenient alias to use `apps` instead of `config.apps`
              _module.args.apps = forgeArgs.config.apps;
            };
            options.apps = lib.mkOption {
              default = { };
              description = "Applications indexed by their `name`.";
              type = treeNode (
                lib.types.submoduleWith {
                  specialArgs = specialArgs // {
                    forgeOptions = forgeArgs.options;
                  };
                  modules = [ ./app.nix ];
                }
              );
            };
          }
        )
      ];
    };
  };

  config =
    let
      shellBundle =
        app:
        let
          appDrv = pkgs.symlinkJoin {
            name = "${app.name}";
            paths = app.programs.packages;
          };
        in
        # Passthru
        appDrv.overrideAttrs (_: {
          passthru = mkPassthru app appDrv;
        });

      mkPassthru =
        app: finalApp:
        let
          testProgramsDrv = pkgs.testers.runCommand {
            name = "${app.name}-test";
            buildInputs = [
              finalApp
            ]
            ++ lib.optional (app.programs.mainPackage != null) app.programs.mainPackage
            ++ app.test.programs.packages;
            script = ''
              ${app.test.programs.script}
              touch $out
            '';
          };
          tests =
            lib.optionalAttrs (app.services.runtimes.container.enable && app.test.services.script != "") {
              test-services-container = app.test.services.result.containerBuild;
            }
            // lib.optionalAttrs (app.services.runtimes.nixos.enable && app.test.services.script != "") {
              test-services-nixos = app.test.services.result.build;
            }
            // lib.optionalAttrs (app.test.programs.script != "") {
              test-programs = testProgramsDrv;
            };
        in
        lib.fix (self: {
          config = app;
          forge.broken = app.broken;
          pkgs = app.packagesList;
        })
        // lib.optionalAttrs app.programs.runtimes.program.enable {
          program = app.programs.mainPackage;
        }
        // lib.optionalAttrs app.services.runtimes.container.enable {
          container = app.services.runtimes.container.result.build;
          services = app.services.runtimes.container.result.shellRunner;
        }
        // lib.optionalAttrs app.services.runtimes.nixos.enable {
          vm = app.services.runtimes.nixos.result.build;
          nixosModules.default = app.services.runtimes.nixos.result.nixosModule;
          nixos = {
            modules = app.services.runtimes.nixos.result.modules;
            vm = app.services.runtimes.nixos.result.build;
          };
        }
        // lib.optionalAttrs app.programs.runtimes.program.enable {
          check-programs-main-package =
            assert
              (app.programs.mainPackage != null)
              || throw "${app.name} has runtimes.program.enable but programs.mainPackage is missing";
            assert
              (lib.hasAttrByPath [ "meta" "mainProgram" ] app.programs.mainPackage)
              || throw "${app.name}'s programs.mainPackage is missing a meta.mainProgram attribute";
            app.programs.mainPackage;
        }
        // tests
        // {
          test = pkgs.linkFarm "${app.name}-tests" (
            lib.mapAttrsToList (name: path: {
              name = lib.removePrefix "test-" name;
              inherit path;
            }) tests
          );
        };

      bundledApps = lib.foldlAttrs (
        acc: name: app:
        lib.recursiveUpdate acc (lib.setAttrByPath app.pos (shellBundle app.val))
      ) config.forge.apps (getEndNodes config.forge.apps);
      packagesWithNamespace = pkgs.callPackage (forge-lib.flakePackagesWithNamespace {
        namespace = "apps";
        derivations = bundledApps;
      }) { };
    in
    {
      packages =
        packagesWithNamespace.packages
        // lib.concatMapAttrs (
          appName: bundled:
          { }
          // lib.optionalAttrs (bundled ? container) { "apps.${appName}.container" = bundled.container; }
          // lib.optionalAttrs (bundled ? program) { "apps.${appName}.program" = bundled.program; }
          // lib.optionalAttrs (bundled ? vm) { "apps.${appName}.vm" = bundled.vm; }
        ) bundledApps;

    };
}
