{
  lib,
  ...
}:
{
  flake.lib = rec {
    # Take an attrset of arbitrary nesting and make it flat
    # by concatenating the nested names with the given separator.
    flattenAttrs =
      separator:
      let
        f = path: lib.concatMapAttrs (flatten path);
        flatten =
          path: name: value:
          if (lib.isAttrs value) && (!lib.isDerivation value) then
            f (path + name + separator) value
          else
            { ${path + name} = value; };
      in
      f "";

    # Compose scopes from dot-separated attribute names:
    #
    # `python3.emerge` -> `{ python3 = { emerge = ...; }; }`
    #
    # Throws if a value already sits at or above a target path, as a name
    # cannot also be used as a scope.
    scopeAttrs =
      {
        type,
        values,
      }:

      assert lib.elem type [
        "apps"
        "pkgs"
      ];

      lib.attrsets.foldlAttrs (
        acc: name: value:
        let
          path = lib.splitString "." name;

          # Recursively check that `path` is available in `tree`, i.e. that no
          # derivation already sits at or above the target location.
          pathIsAvailable =
            path: tree:
            let
              nodeIsAvailable = parts: node: !(lib.hasAttr (lib.head parts) node);

              walk =
                parts: node:
                if lib.isDerivation node then
                  false
                else if parts == [ ] || nodeIsAvailable parts node then
                  true
                else
                  walk (lib.tail parts) node.${lib.head parts};
            in
            walk path tree;

          throwOverlap = throw "Can not evaluate \"${type}.${name}\" as that path is already contained in ${type}. This is likely due to a name overlapping with the name of a scope.";

          scopedValue = lib.attrsets.setAttrByPath path value;
        in
        assert (pathIsAvailable path acc) || throwOverlap;
        lib.attrsets.recursiveUpdate acc scopedValue
      ) { } values;

    # Helper to support namespacing with dot (`.`) in `flake.packages`
    # (eg. `nix build .#pkgs.${packageName}`).
    # This relies on the Nix completion not quoting attrset keys containing
    # a dot.
    flakePackagesWithNamespace =
      { namespace, derivations }:
      { linkFarm, stdenv }:
      let
        # Flakes don't accept attribute sets, so here we recursively collect
        # derivation leaves along with their dotted names, so that nested
        # scopes (e.g. `pkgs.python3.emerge`) can be exported.
        leaves = flattenAttrs "." derivations;

        bundle = linkFarm namespace leaves;
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
        // lib.mapAttrs' (name: lib.nameValuePair "${namespace}.${name}") leaves;

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
        base,
        from,
        to,
      }:
      { config, options, ... }:
      lib.recursiveUpdate
        (lib.modules.doRename
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
          }
        )
        {
          # FixMe(performance): using a Markdown link reloads the page.
          # An alternative could be to generate {options}`path.to.option` like in `lib.doRename`
          # and extend the Markdown parser to handle it properly on the Elm side.
          options = lib.setAttrByPath (from ++ [ "description" ]) ''
            ${getOptionFromPath options (to ++ [ "description" ])}

            Alias of: [`${lib.concatStringsSep "." (base ++ to)}`](recipe/options?s=${
              lib.concatStringsSep "." (base ++ to)
            })
          '';
        };

    # Show active warnings, then throw on failed assertions,
    # otherwise return `value`.
    # `assertions` and `warnings` are lists of `{ condition, message }`
    # (see `forge/modules/assertions-warnings.nix`).
    checkAssertionsWarnings =
      { assertions, warnings }:
      value:
      let
        activeWarnings = lib.filter (x: x.condition) warnings;
        failedAssertions = lib.filter (x: !x.condition) assertions;
        assertionMessages = lib.concatMapStringsSep "\n" (x: "- ${x.message}") failedAssertions;

        checkedValue = lib.throwIf (
          failedAssertions != [ ]
        ) "\nFailed assertions:\n${assertionMessages}" value;
      in
      lib.foldr (w: acc: lib.warn w.message acc) checkedValue activeWarnings;

    # Get the Nix store hash of a derivation's output path
    # (eg. `/nix/store/<hash>-name` -> `<hash>`).
    nixStoreHash = drv: lib.unsafeDiscardStringContext (lib.substring 0 32 (baseNameOf drv.outPath));

    # Convert derivations to a schema that will be consumed by the UI
    toDrvSchema = drv: {
      name = drv.name or "";
      pname = drv.pname or "";
      version = drv.version or "";
      broken = isBroken drv;
      unfree = isUnfree drv;
    };

    # Recursively remove Nix context used to track dependencies.
    # Useful to avoid building the derivations contained in a `config`
    # when serializing it (eg. with `builtins.toJSON`).
    scrubNixContext =
      x:
      if lib.isString x then
        lib.unsafeDiscardStringContext x
      else if lib.isDerivation x then
        toDrvSchema x
      else if lib.isFunction x then
        null
      else if lib.isList x then
        map scrubNixContext x
      else if lib.isAttrs x then
        lib.mapAttrs (n: v: if n == "__toString" then v else scrubNixContext v) x
      else
        x;

    isBroken =
      x: lib.attrByPath [ "forge" "broken" ] false x || lib.attrByPath [ "meta" "broken" ] false x;

    isUnfree =
      x: lib.attrByPath [ "forge" "unfree" ] false x || lib.attrByPath [ "meta" "unfree" ] false x;

    # Helper to convert a flake URL shorthand (e.g. "github:owner/repo")
    # into a standard HTTP/HTTPS web URL.
    showNixUrl =
      url:
      if lib.hasPrefix "github:" url then
        "https://github.com/" + lib.removePrefix "github:" url
      else if lib.hasPrefix "gitlab:" url then
        "https://gitlab.com/" + lib.removePrefix "gitlab:" url
      else if lib.hasPrefix "codeberg:" url then
        "https://codeberg.org/" + lib.removePrefix "codeberg:" url
      else
        url;

    # Function for triggering warning messages only when building/evaluating a
    # derivation. For this purpose, wrapping its `drvPath` and `outPath`
    # attributes is enough.
    #
    # NOTE: if we wrap other attrs (e.g. with `lib.warnOnInstantiate`), we risk
    # the messsage being printed mistakingly if those attributes are evaluated,
    # especially when we do this for all packages (e.g. filtering flake checks).
    warnOnBuild =
      msg: drv:
      let
        warnedDrv = lib.warn msg drv;
      in
      drv
      // {
        drvPath = warnedDrv.drvPath;
        outPath = warnedDrv.outPath;
      };

    handleUnfree =
      pkgs: drv:
      let
        isApp = drv ? forge && drv.forge._recipeType == "apps";
        isPkg = !isApp;

        drvName = if isPkg then "pkgs.${drv.pname}" else "apps.${drv.name}";
        drvIsUnfree = if isPkg then drv.unfree else drv.forge.unfree;

        warnedDrv = warnOnBuild ''
          '${drvName}' is unfree or depends on an unfree package.

          To build it, you must allow unfree packages in your forge flake:

          ```
          perSystem =
            { config, pkgs, ... }:
            {
              forge {
                allowUnfree = true;
              };
            };
          ```
        '' pkgs.emptyFile;
      in
      if !drvIsUnfree || pkgs.config.allowUnfree then
        if isPkg then drv.result.derivation else drv
      else
        # Replace the main derivation and all its passthru attributes with
        # fake ones that carry the unfree warning.
        # This is to make sure that we don't evaluate the real ones.
        # Keep `forge`, which only has metadata, such as `unfree`.
        warnedDrv
        // lib.optionalAttrs isApp (
          lib.mapAttrs (_: v: warnedDrv) drv.passthru // { inherit (drv) forge; }
        );

    # Application categories (eg. `forge-lib.categories.Development`).
    categories = lib.listToAttrs (
      map (c: lib.nameValuePair c.name c) (import ../../maintainers/categories-list.nix)
    );

    # Re-usable snippets in Markdown format (eg. `forge-lib.snippets.usage app`).
    snippets = import ../../maintainers/snippets-list.nix { inherit lib; };

    # Check that the app `appName` declares the `parameters` in `declaredParameters`,
    # with the same types.
    checkParameters =
      {
        appName,
        declaredParameters,
        parameters,
      }:
      let
        names = lib.concatStringsSep ", " (lib.attrNames declaredParameters);
        typeName =
          value:
          {
            int = "an integer";
            string = "a string";
            bool = "a boolean";
          }
          .${lib.typeOf value} or (lib.typeOf value);
        checked = lib.mapAttrs (
          name: value:
          if !declaredParameters ? ${name} then
            throw "The app `${appName}` has no parameter `${name}`. Available parameters: ${
              if names == "" then "none" else names
            }."
          else if lib.typeOf value != lib.typeOf declaredParameters.${name} then
            throw "The parameter `${name}` of the app `${appName}` must be ${
              typeName declaredParameters.${name}
            }, not ${typeName value}."
          else
            value
        ) parameters;
      in
      # Check all the parameters now, also those that the recipe does not read
      # (for example a parameter that the app does not declare).
      lib.deepSeq checked checked;

    # Convert the strings of the parameters (eg. from the command line)
    # to the types that the app `appName` declares in `declaredParameters`.
    # Parameters that the app does not declare stay strings,
    # for `checkParameters` to report them.
    parametersFromStrings =
      {
        appName,
        declaredParameters,
        parameterStrings,
      }:
      lib.mapAttrs (
        name: value:
        let
          declaredValue = declaredParameters.${name};

          throwExpected =
            expected:
            throw "The parameter `${name}` of the app `${appName}` must be ${expected}, not `${value}`.";

          parseBool =
            value:
            if value == "true" then
              true
            else if value == "false" then
              false
            else
              throwExpected "`true` or `false`";

          parseInt =
            value:
            if lib.strings.match "-?[0-9]+" value != null then lib.toInt value else throwExpected "an integer";

          convert =
            value:
            if lib.isBool declaredValue then
              parseBool value
            else if lib.isInt declaredValue then
              parseInt value
            else
              value;
        in
        if declaredParameters ? ${name} then convert value else value
      ) parameterStrings;
  };
}
