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
          name = lib.removePrefix "perSystem." opt.name;
          declarations = [ ];
          visible = lib.hasPrefix "perSystem.forge." opt.name;
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

  # Convert app screenshots to WebP in two sizes:
  # `<n>.webp` for the full view and `<n>-thumb.webp` for the gallery.
  appScreenshots = pkgs.linkFarm "app-screenshots" (
    map (app: {
      name = app.name;
      path = pkgs.symlinkJoin {
        name = "${app.name}-screenshots";
        paths = lib.imap0 (
          index: screenshot:
          pkgs.runCommand "${app.name}-screenshot-${toString index}"
            {
              nativeBuildInputs = [ pkgs.imagemagick ];
            }
            ''
              mkdir -p $out
              # `[0]` selects the first frame of an animated image.
              magick '${screenshot.file}[0]' -resize '1600x>' -quality 85 $out/${toString index}.webp
              magick '${screenshot.file}[0]' -resize '752x>' -quality 80 $out/${toString index}-thumb.webp
            ''
        ) app.screenshots;
      };
    }) (lib.filter (app: app.screenshots != [ ]) (lib.attrValues forgeApps))
  );

  forgeConfig = config.forge // {
    pkgs = lib.filterAttrs (_: pkg: !pkg.broken) config.forge.pkgs;
    apps = lib.filterAttrs (_: app: !app.broken) config.forge.apps;
  };

  _forge = {
    inherit appScreenshots;

    config = pkgs.writeTextFile {
      name = "forge-config.json";
      text = lib.toJSON (forge-lib.scrubNixContext forgeConfig);
    };

    options = pkgs.runCommand "options.json" { } ''
      cp ${forgeOptions.optionsJSON}/share/doc/nixos/options.json $out
    '';

    ui = pkgs.callPackage ../ui/package.nix {
      inherit (config.packages) _forge;
      inherit appIcons appScreenshots;
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
  packages = lib.mkIf config.forge.enable packagesWithNamespace.packages;
}
