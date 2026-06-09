{
  forgeApps,
  pkgs,
  lib,
}:

let
  # Read the list of grants from grants option
  grants = lib.attrNames (
    (lib.evalModules {
      modules = [ ../forge/modules/apps/ngi/grants.nix ];
    }).options
  );

  mkReport =
    grant:
    let
      # Example apps are excluded
      baseList = lib.filter (app: app.name != "example") (lib.attrValues forgeApps);

      appList =
        if grant == null then
          baseList
        else
          lib.filter (app: lib.hasAttr grant app.ngi.grants && app.ngi.grants.${grant} != [ ]) baseList;

      grantCounts =
        let
          allGrants = lib.concatMap (
            app: lib.attrNames (lib.filterAttrs (_: v: v != [ ]) app.ngi.grants)
          ) appList;
        in
        lib.foldl' (acc: g: acc // { ${g} = (acc.${g} or 0) + 1; }) { } allGrants;

      appLines = lib.concatMapStringsSep "\n" (
        app:
        let
          appGrants = lib.pipe app.ngi.grants [
            (lib.filterAttrs (_: v: v != [ ]))
            lib.attrNames
            (lib.concatStringsSep ", ")
          ];
          grantStr = if appGrants != "" then " (${appGrants})" else "";
        in
        "  - [${app.displayName}](https://ngi.nixos.org/app/${app.name})${grantStr}"
      ) (lib.sortOn (app: app.displayName) appList);

      grantHeader = if grant == null then "all grants" else grant;
      countApps = toString (lib.length appList);
      countCommons = toString (grantCounts.Commons or 0);
      countCore = toString (grantCounts.Core or 0);
      countEntrust = toString (grantCounts.Entrust or 0);
      countReview = toString (grantCounts.Review or 0);

      report = pkgs.writeText "report-packaging.md" ''
        ## Summary - ${grantHeader} grant(s)

        - Apps: ${countApps}

        ${lib.optionalString (grant == null) ''
          ### Grants

          - Commons: ${countCommons}
          - Core: ${countCore}
          - Entrust: ${countEntrust}
          - Review: ${countReview}
        ''}
        ## Apps

        ${appLines}
      '';
    in
    pkgs.writeShellApplication {
      name = "report-packaging";
      text = "cat ${report}";
    };
in
lib.listToAttrs (map (g: lib.nameValuePair g (mkReport g)) grants) // { all = mkReport null; }
