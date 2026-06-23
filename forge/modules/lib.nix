{
  lib,
  ...
}:
{
  flake.lib = {
    # Helper to support namespacing with dot (`.`) in `flake.packages` (eg. `nix build .#pkgs.${packageName}`}
    # This relies on the Nix completion not quoting attrset keys containing a dot.
    flakePackagesWithNamespace =
      { namespace, derivations }:
      { linkFarm, stdenv }:
      {
        packages = {
          ${namespace} =
            let
              bundle = linkFarm namespace (
                lib.mapAttrsToList (name: path: {
                  inherit name path;
                }) derivations
              );
            in
            derivations
            // {
              name = namespace;
              type = "derivation";
              inherit (stdenv.hostPlatform) system;
              inherit (bundle) drvPath outPath outputName;
              # In case flake schemas ever gets merged this will be useful
              # if using `lix` you can see this description in the output of `nix flake show`
              meta.description = "Build all ${namespace} at once";
            };
        }
        // lib.mapAttrs' (name: lib.nameValuePair "${namespace}.${name}") derivations;

        legacyPackages = {
          # Tip(debugging): use this when not using the Flake setup (`nix repl -f.`)
          # to get a curated list of packages `pkgs.<Tab>`
          # In the Flake setup, it's equivalent to use `nix flake show`.
          # This is because simply querying `pkgs` will not display the list,
          # `pkgs` being a derivation and not an attrset of derivations
          # also in the Traditional setup to keep consistency between Flake and Traditional.
          "${namespace}Repl" = derivations;
        };
      };
  };
}
