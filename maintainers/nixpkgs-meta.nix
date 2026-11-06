/*
  To catch any links in the meta section like changelog or homepage which could be broken:

  export GITHUB_TOKEN=$(gh auth token)
  ./maintainers/nixpkgs-meta-failures.py > failures.json

  # Or run steps manually:
  nix eval --raw --extra-experimental-features pipe-operators -f maintainers/nixpkgs-meta.nix metaCSV > pkgs.csv
  export GITHUB_TOKEN=$(gh auth token)
  nix run .#apps.lychee -- -v pkgs.csv -m 5 -f json | tee lychee.json
  ./maintainers/nixpkgs-meta-failures.py pkgs.csv lychee.json | tee failures.json
*/
let
  out = import ./list-nixpkgs.nix { };
  inherit (out.pkgs) pkgs lib;
  packages =
    out.packages
    |> map (x: lib.nameValuePair x (lib.getAttrFromPath (lib.splitString "." x) out.pkgs))
    |> lib.listToAttrs;
  meta =
    packages
    |> lib.mapAttrs (
      k: v:
      let
        pos = v.meta.position or "";
        file = if lib.hasInfix "/pkgs/" pos then "pkgs/" + lib.last (lib.splitString "/pkgs/" pos) else pos;
      in
      (lib.optionalString (lib.hasAttr "changelog" v.meta) "${k},changelog,${file},${v.meta.changelog}\n")
      + "${k},homepage,${file},${v.meta.homepage}"
    )
    |> builtins.attrValues;
  metaCSV = lib.concatStringsSep "\n" meta;
in
{
  inherit
    lib
    pkgs
    packages
    meta
    metaCSV
    ;
}
