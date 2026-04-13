{
  lib,
  pkgs,
  inputs,

  # toplevel attributes
  formatter,
  ...
}:
let
  devshell = import inputs.devshell { nixpkgs = pkgs; };

  devshellEnv = lib.makeExtensible (final: {
    name = "devshell";

    motd = ''

      {33}❄️ Welcome to NGI Forge{reset}

      {85}📖 Website: https://ngi-nix.github.io/forge 💬 Chat: #ngipkgs:nixos.org (Matrix){reset}
      $(type -p menu &>/dev/null && menu)

      {123}Tip:{reset} DEVSHELL_NO_MOTD=1 will disable this welcome message
    '';

    generalCategory = "[general commands]";

    mkAliases =
      {
        aliases,
        category ? final.generalCategory,
      }:
      lib.mapAttrsToList (name: value: {
        inherit name;
        command = value.cmd;
        # fallback to category and thus generalCategory if not specified
        category = value.category or category;
        # fallback to `cmd` if help is not specified
        help = value.help or value.cmd;
      }) aliases;

    mapCommands =
      category: packages:
      builtins.map (p: {
        inherit category;
        package = p;
      }) packages;

    commands = (final.mapCommands "formatter" final.formatters) ++ final.defaultCmds ++ final.aliases;

    # NOTE: hidden in the menu
    packages = final.packagesFrom' formatter.shell;

    # NOTE: inputsFrom equivalent; hidden in the menu
    packagesFrom = [ ];

    finalPackage = final.eval.shell;

    eval = devshell.eval {
      configuration = (
        lib.filterAttrs (
          name: value:
          # filter only the valid args for devshell.eval
          builtins.elem name [
            "name"
            "motd"
            "commands"
            "packages"
            "packagesFrom"

            "devshell"
            "bash"
          ]
        ) final
      );
    };

    # devshell accepts no shellHook but we can use the extra or interactive blocks it provides
    # also can use devshell.startup.* or devshell.interactive.* with lib.noDepEntry
    devshell.startup.bash_extra_more = lib.noDepEntry final.shellHook;

    # disables devshell to change the prompt in anyway
    devshell.interactive.PS1 = lib.noDepEntry "";

    # default empty shellHook, implies no override
    shellHook = "";

    # from numtide/devshell, copyright Numtide, MIT licensed
    # Returns a list of all the input derivation ... for a derivation.
    inputsOf =
      drv:
      lib.filter lib.isDerivation (
        (drv.buildInputs or [ ])
        ++ (drv.nativeBuildInputs or [ ])
        ++ (drv.propagatedBuildInputs or [ ])
        ++ (drv.propagatedNativeBuildInputs or [ ])
      );

    # from numtide/devshell, copyright Numtide, MIT licensed
    # given a shell get the "packages" from the shell
    packagesFrom' = shell: lib.foldl' (sum: drv: sum ++ (final.inputsOf drv)) [ ] [ shell ];

    # Include formatter packages. Format with:
    # $ treefmt
    # $ nix fmt
    formatters = [ formatter.package ];

    # Aliases are wrapper commands which will run the specified `cmd`
    # `help` exists to customise the menu entry
    aliases = final.mkAliases {
      aliases = {
        reload.cmd = "direnv reload";
        reload.help = "reload the direnv shell";

        # Adds a `shell` wrapper/alias pointing to the currently active shell
        shell.cmd = "${final.name} \"$@\"";
        shell.help = "run any command via the devshell, see shell -h";
      };
    };
    # requires a different name as "commands" can't be used
    # because unlike other attributes "commands" needs to be built from a few `final` attributes
    defaultCmds =
      let
        src = ./commands;

        files = lib.fileset.toList (
          lib.fileset.intersection (lib.fileset.gitTracked ../..) (
            lib.fileset.fileFilter (file: file.hasExt "nix") src
          )
        );

        callPackage' = pkgs.newScope { devshellEnv = final; };

        getCategory =
          file:
          let
            parentDir = dirOf file;
            grandParentDir = dirOf parentDir;
            isDefault = baseNameOf file == "default.nix";
          in
          # ./commands/<command.nix>
          if parentDir == src then
            final.generalCategory
          # ./commands/<command>/default.nix
          else if isDefault && grandParentDir == src then
            final.generalCategory
          # ./commands/<category>/<command>/default.nix
          else if isDefault then
            baseNameOf grandParentDir
          # ./commands/<category>/<command.nix>
          else
            baseNameOf parentDir;

        groupedFiles = builtins.groupBy getCategory files;
      in
      lib.concatLists (
        lib.mapAttrsToList (
          category: categoryFiles:
          final.mapCommands category (builtins.map (path: callPackage' path { }) categoryFiles)
        ) groupedFiles
      );
  });
in
devshellEnv
