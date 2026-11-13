/*
  To catch any links in NGI Forge recipes (apps and pkgs) which could be broken:

  export GITHUB_TOKEN=$(gh auth token)
  ./maintainers/forge-meta-failures.py | tee failures.json

  # Or run steps manually:
  nix eval --raw --extra-experimental-features pipe-operators -f maintainers/forge-meta.nix metaCSV > forge.csv
  export GITHUB_TOKEN=$(gh auth token)
  nix run .#apps.lychee -- -v forge.csv -m 5 -f json | tee lychee.json
  ./maintainers/forge-meta-failures.py forge.csv lychee.json | tee failures.json
*/
let
  out = import ../default.nix { };
  inherit (out) forge lib;
  apps = forge.apps;
  pkgs = forge.pkgs;

  extractUrls =
    str:
    let
      parts = builtins.split "(https?://[^] \t\r\n\"'()<>,;[]+)" str;
      rawUrls = builtins.concatLists (builtins.filter builtins.isList parts);
      cleanUrls = map (lib.removeSuffix ".") rawUrls;
    in
    builtins.filter (
      u:
      !(lib.hasPrefix "http://localhost" u)
      && !(lib.hasPrefix "https://localhost" u)
      && !(lib.hasPrefix "http://127.0.0.1" u)
      && !(lib.hasPrefix "https://127.0.0.1" u)
      && !(lib.hasPrefix "http://example.com" u)
      && !(lib.hasPrefix "https://example.com" u)
      && !(lib.hasPrefix "http://example.org" u)
      && !(lib.hasPrefix "https://example.org" u)
    ) cleanUrls;

  extractCommentUrls =
    file:
    if file == null || file == "" then
      [ ]
    else
      let
        content = builtins.readFile (../. + "/${file}");
        lines = lib.splitString "\n" content;
        commentLines = builtins.filter (l: builtins.match "^.*(#|/\\*|\\*).*https?://.*$" l != null) lines;
      in
      builtins.concatLists (map extractUrls commentLines);

  sourceGitToUrl =
    git:
    if git == null || git == "" then
      null
    else
      let
        parts = lib.splitString ":" git;
        forgeName = builtins.head parts;
        rest = lib.concatStringsSep ":" (builtins.tail parts);
        subparts = lib.splitString "/" rest;
      in
      if forgeName == "github" || forgeName == "gitlab" || forgeName == "codeberg" then
        let
          domain =
            if forgeName == "github" then
              "github.com"
            else if forgeName == "gitlab" then
              "gitlab.com"
            else
              "codeberg.org";
        in
        "https://" + domain + "/" + builtins.elemAt subparts 0 + "/" + builtins.elemAt subparts 1
      else if forgeName == "forgejo" || forgeName == "gitea" then
        "https://"
        + builtins.elemAt subparts 0
        + "/"
        + builtins.elemAt subparts 1
        + "/"
        + builtins.elemAt subparts 2
      else if forgeName == "git" then
        builtins.head (lib.splitString "?" rest)
      else
        null;

  appRows =
    app:
    let
      name = app.outputName;
      file = app.recipePath;
    in
    (lib.optional (
      app.links.website or null != null && app.links.website != ""
    ) "${name},links.website,${file},${app.links.website}")
    ++ (lib.optional (
      app.links.source or null != null && app.links.source != ""
    ) "${name},links.source,${file},${app.links.source}")
    ++ (lib.optional (
      app.links.docs or null != null && app.links.docs != ""
    ) "${name},links.docs,${file},${app.links.docs}")
    ++ (map (u: "${name},usage,${file},${u}") (extractUrls (app.usage or "")))
    ++ (map (u: "${name},description,${file},${u}") (extractUrls (app.description or "")))
    ++ (builtins.concatLists (
      map
        (
          fund:
          map (g: "${name},ngi.grants.${fund},${file},https://nlnet.nl/project/${g}/") (
            app.ngi.grants.${fund} or [ ]
          )
        )
        [
          "Commons"
          "Core"
          "Entrust"
          "Review"
        ]
    ))
    ++ (map (u: "${name},comments,${file},${u}") (extractCommentUrls file));

  pkgRows =
    pkg:
    let
      name = pkg.outputName;
      file = pkg.recipePath;
      gitUrl = sourceGitToUrl (pkg.source.git or null);
    in
    (lib.optional (
      pkg.homePage or null != null && pkg.homePage != ""
    ) "${name},homePage,${file},${pkg.homePage}")
    ++ (lib.optional (
      pkg.source.url or null != null && pkg.source.url != ""
    ) "${name},source.url,${file},${pkg.source.url}")
    ++ (lib.optional (gitUrl != null) "${name},source.git,${file},${gitUrl}")
    ++ (map (u: "${name},description,${file},${u}") (extractUrls (pkg.description or "")))
    ++ (map (u: "${name},comments,${file},${u}") (extractCommentUrls file));

  meta = lib.unique (
    (builtins.concatLists (map appRows (builtins.attrValues apps)))
    ++ (builtins.concatLists (map pkgRows (builtins.attrValues pkgs)))
  );

  metaCSV = lib.concatStringsSep "\n" meta;
in
{
  inherit
    lib
    apps
    pkgs
    meta
    metaCSV
    ;
}
