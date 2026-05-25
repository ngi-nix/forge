{
  forge-inputs,
  lib,
  config,
  ...
}:
{
  flake.lib = {
    # recipeFiles :: Options -> listOf path
    # `recipeFiles options` returns the paths used to define
    # the given `options` and its sub-`options` recursively.
    recipeFiles =
      let
        loop =
          options:
          lib.unique (
            lib.concatMap (
              v:
              lib.optionals (v ? "files") v.files ++ lib.optionals (v ? "type") (loop (v.type.getSubOptions [ ]))
            ) (lib.attrValues options)
          );
      in
      loop;

    # recipeInputs :: [{ [String] :: Inputs }] -> { [String] :: Repository } -> Options -> [URL]
    # `recipeInputs inputs repositories options`
    # returns URLs to the recipe files found in `options`'s `files`.
    recipeUrls =
      inputs: repositories: options:
      let
        inputPaths = lib.concatMap (lib.mapAttrsToList (n: v: v.outPath)) inputs;
      in
      lib.concatMap (
        recipePath:
        let
          matchingInput = lib.findFirst (input: lib.hasPrefix input recipePath) null inputPaths;
          file = lib.removePrefix "${matchingInput}/" recipePath;
          inputString = lib.unsafeDiscardStringContext matchingInput;
        in
        lib.optional
          (
            matchingInput != null
            && lib.hasAttr inputString repositories
            # Remove files providing default definitions from ngi-forge
            && (matchingInput != forge-inputs.self.outPath || !(lib.hasPrefix "forge/" file))
          )
          # Warning(portability): assume the file goes at the end of the URL
          # to avoid using a function.
          "${repositories.${inputString}.treeUrl}/${file}"
      ) (config.flake.lib.recipeFiles options);

    # `sourceInfoRef input` returns a commit reference of the given `input`
    # or some approximation.
    sourceInfoRef =
      input:
      if input.sourceInfo ? "shortRev" then
        input.sourceInfo.shortRev
      else if input.sourceInfo ? "dirtyShortRev" then
        lib.removeSuffix "-dirty" input.sourceInfo.dirtyShortRev
      else if input.sourceInfo ? "rev" then
        input.sourceInfo.rev
      else
        "@";
  };
}
