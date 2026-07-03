{
  config,
  lib,
  pkgs,
  forge-inputs,
  forge-lib,
  flake-parts-lib,
  ...
}:

let
  evalForgeModules =
    modules:
    flake-parts-lib.evalFlakeModule {
      inputs = forge-inputs;
    } { imports = modules; };

  forgeOptionsDoc =
    modules:
    pkgs.nixosOptionsDoc {
      warningsAreErrors = false;
      options = lib.removeAttrs (evalForgeModules modules).options [ "_module" ];
      transformOptions =
        opt:
        opt
        // {
          name = lib.removePrefix "perSystem.forge." opt.name;
          declarations = [ ];
          visible = lib.match ("^perSystem\\.forge\\.(apps|pkgs)(\\..+)?") opt.name != null;
        };
    };

  forgeApps = config.forge.apps;
  forgeOptions = forgeOptionsDoc [
    forge-inputs.self.flakeModules.base
  ];

  # Collect app icons into a derivation
  appIcons = pkgs.runCommand "app-icons" { } ''
    mkdir -p $out
    ${lib.concatStringsSep "\n" (
      map (app: ''
        mkdir -p $out/${app.name}
        ${if app.icon or null != null then "cp ${app.icon} $out/${app.name}/icon.svg" else ""}
      '') (lib.attrValues forgeApps)
    )}
  '';

  _forge = {
    config = pkgs.writeTextFile {
      name = "forge-config.json";
      text =
        let
          scrubConfig =
            x:
            if lib.isString x || lib.isDerivation x then
              lib.unsafeDiscardStringContext x
            else if lib.isList x then
              map scrubConfig x
            else if lib.isAttrs x then
              lib.mapAttrs (n: v: scrubConfig v) x
            else
              x;
        in
        builtins.toJSON (scrubConfig config.forge);
    };

    options = pkgs.runCommand "options.json" { } ''
      cp ${forgeOptions.optionsJSON}/share/doc/nixos/options.json $out
    '';

    ui = pkgs.callPackage ../ui/package.nix {
      inherit (config.packages) _forge;
      inherit appIcons;
      buildElmApplication = (forge-inputs.elm2nix.lib.elm2nix pkgs).buildElmApplication;
      highlight-js = pkgs.callPackage ../flake/packages/highlight-js.nix { };
    };

    ui-dev = pkgs.callPackage ../flake/packages/forge-ui-dev.nix {
      inherit (config.packages) _forge;
      highlight-js = pkgs.callPackage ../flake/packages/highlight-js.nix { };
    };

    docs = pkgs.callPackage ../flake/packages/forge-docs.nix { };

    report =
      let
        reports = import ../maintainers/mk-report.nix { inherit forgeApps pkgs lib; };
      in
      pkgs.writeShellApplication {
        name = "report-packaging";
        passthru = reports;
        text = ''
          cat <<EOF
          To generate a packaging report, use:

          \`\`\`
          nix run .#_forge.report.all      # all grants
          nix run .#_forge.report.<GRANT>  # single grant
          \`\`\`

          Available grants:
          ${lib.concatMapStringsSep "\n" (g: "- " + g) [
            "Commons"
            "Core"
            "Entrust"
            "Review"
          ]}
          EOF
        '';
      };

    announcement = pkgs.writeShellApplication {
      name = "announce-projects";
      passthru = import ../maintainers/mk-announcement.nix { inherit forgeApps pkgs lib; };
      text = ''
        cat <<EOF
        To generate project announcement, use:

        \`\`\`
        nix run .#_forge.announcement.<APP_NAME>
        \`\`\`

        Available apps:
        ${lib.concatMapStringsSep "\n" (app: "- " + app.name) (lib.attrValues forgeApps)}
        EOF
      '';
    };
  };
  packagesWithNamespace = pkgs.callPackage (forge-lib.flakePackagesWithNamespace {
    namespace = "_forge";
    derivations = _forge;
  }) { };
in
{
  inherit (packagesWithNamespace) packages;
}
