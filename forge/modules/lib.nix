{
  lib,
  config,
  ...
}:
{
  flake.lib = {
    # Helper to support namespacing with dot (`.`) in `flake.packages`
    # (eg. `nix build .#pkgs.${packageName}`).
    # This relies on the Nix completion not quoting attrset keys containing
    # a dot.
    flakePackagesWithNamespace =
      { namespace, derivations }:
      { linkFarm, stdenv }:
      let
        bundle = linkFarm namespace (
          lib.mapAttrsToList (name: path: {
            inherit name path;
          }) derivations
        );
      in
      {
        packages = {
          ${namespace} = derivations // {
            all = bundle;
            name = namespace;
            type = "derivation";
            inherit (stdenv.hostPlatform) system;
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
    # Like `lib.getAttrFromPath`, but support `lib.types.submodule`.
    getOptionFromPath =
      opts: path:
      let
        opt = opts.${lib.head path};
      in
      if lib.length path == 1 then
        opt
      else
        # Recurse into next path element,
        # skipping `.valueMeta.configuration.options` when `opts` is a `lib.types.submodule`.
        getOptionFromPath (
          if (opt._type or "") == "option" then opt.valueMeta.configuration.options or opt else opt
        ) (lib.tail path);
    # Like `lib.mkAliasOptionModule`, but support `lib.types.submodule`.
    mkAliasOptionModule =
      {
        condition,
        from,
        to,
      }:
      { config, options, ... }:
      lib.modules.doRename
        {
          inherit from to;
          visible = true;
          warn = false;
          use = lib.id;
          # Note that `condition` wraps in `lib.mkIf` the generated `config`
          # but is not available to set in `lib.modules.mkAliasOptionModule`
          # hence use `lib.modules.doRename` directly to set it.
          inherit condition;
        }
        {
          inherit config;
          # `lib.modules.doRename` does not expect the sub-`options` introduced by `lib.types.submodule`, hence remove them.
          options = lib.setAttrByPath from (getOptionFromPath options from);
        };

    # Get the Nix store hash of a derivation's output path
    # (eg. `/nix/store/<hash>-name` -> `<hash>`).
    nixStoreHash = drv: lib.unsafeDiscardStringContext (lib.substring 0 32 (baseNameOf drv.outPath));

    # Recursively remove Nix context used to track dependencies.
    # Useful to avoid building the derivations contained in a `config`
    # when serializing it (eg. with `builtins.toJSON`).
    scrubNixContext =
      x:
      if lib.isString x || lib.isDerivation x then
        lib.unsafeDiscardStringContext x
      else if lib.isFunction x then
        null
      else if lib.isList x then
        map config.flake.lib.scrubNixContext x
      else if lib.isAttrs x then
        lib.mapAttrs (n: v: if n == "__toString" then v else config.flake.lib.scrubNixContext v) x
      else
        x;
  };
}
