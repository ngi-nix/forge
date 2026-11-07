# Build the executable that starts a service component.
#
# The executable puts `process.configData` into `$XDG_CONFIG_HOME` (a new
# temporary directory if the variable is not set), runs
# `process.preStart` and then runs `process.command`.
#
# If `configOverrideDir` contains a file at the `path` of a `process.configData`
# item, the service gets that file instead of the file from the build.
#
# The service gets `process.argv` as double-quoted shell words. Thus, `$VAR` and
# `${VAR}` expand at service start and each item stays one argument. `$$` is a
# literal `$`. Other shell syntax has no special meaning.
#
# The service then gets the flags of `process.parameters` and last the arguments
# of the executable. Thus, a user can give more arguments to a built service.
#
# Set `parseArguments` if a user controls the arguments of the executable, for
# example in a container. The executable then removes these arguments before it
# forwards the other arguments to the service:
#
# - A flag of `process.parameters` sets the value of that parameter. Thus, the
#   service gets the flag one time.
# - `--forge-help` shows the available configuration and stops.
# - `--` stops the parsing. The service gets all arguments after it.
#
# Set `supervise` if no service manager controls the process, for example in a
# container. The executable then runs `setup` one time, restarts the service
# after a failure and forwards termination signals to the service. It also
# collects orphaned processes when it runs as PID 1.
{
  lib,
  pkgs,
  name,
  service,
  setup ? "",
  supervise ? false,
  configOverrideDir ? null,
  parseArguments ? false,
}:
let
  inherit (pkgs) coreutils;
  inherit (service) process;

  command = if lib.isDerivation process.command then lib.getExe process.command else process.command;

  quoteArg =
    arg:
    ''"${lib.replaceStrings [ "\\" "\"" "`" "$(" "$$" ] [ "\\\\" "\\\"" "\\`" "\\$(" "\\$" ] arg}"'';

  configFiles = lib.filter (file: file.enable) (lib.attrValues process.configData);

  linkConfigFile = file: ''
    source=${lib.escapeShellArg "${file.source}"}
    ${lib.optionalString (configOverrideDir != null) ''
      override=${lib.escapeShellArg "${configOverrideDir}/${file.path}"}
      if [ -e "$override" ]; then source=$override; fi
    ''}
    echo ${lib.escapeShellArg "Config: ${file.path} -> "}"$source" >&2
    ${coreutils}/bin/mkdir --parents "$XDG_CONFIG_HOME"/${lib.escapeShellArg (dirOf file.path)}
    ${coreutils}/bin/ln --symbolic --force "$source" \
      "$XDG_CONFIG_HOME"/${lib.escapeShellArg file.path}
  '';

  addFlag =
    name: parameter:
    let
      value = "\"\${${name}:-}\"";
      flag = lib.escapeShellArg parameter.flag;
    in
    if parameter.type == "boolean" then
      ''
        if [ ${value} = true ]; then args+=(${flag}); fi
      ''
    else
      ''
        if [ -n ${value} ]; then args+=(${flag} ${value}); fi
      '';

  flagParameters = lib.filterAttrs (_: parameter: parameter.flag != null) process.parameters;

  parseFlag =
    name: parameter:
    let
      flag = lib.escapeShellArg parameter.flag;
      flagWithValue = ''
        ${flag}=*)
          export ${name}="''${1#*=}"
          shift
          ;;
      '';
    in
    if parameter.type == "boolean" then
      ''
        ${flag})
          export ${name}=true
          shift
          ;;
        ${flagWithValue}
      ''
    else
      ''
        ${flag})
          needValue "$@"
          export ${name}="$2"
          shift 2
          ;;
        ${flagWithValue}
      '';

  help = pkgs.writeText "${name}-help" (
    let
      section = title: lines: lib.optionalString (lines != [ ]) "\n${title}\n${lib.concatStrings lines}";

      describeParameter =
        variable: parameter:
        let
          details = lib.filter (detail: detail != null) [
            parameter.description
            (if parameter.enum != null then "One of: ${lib.concatStringsSep ", " parameter.enum}." else null)
            (if parameter.default != null then "Default: ${toString parameter.default}." else null)
          ];
        in
        "  ${variable}${
            lib.optionalString (parameter.flag != null) ", ${parameter.flag}"
          }\n      ${lib.concatStringsSep " " details}\n";

      describeFile = file: "  ${file.path}\n";

      describeReference = title: link: lib.optional (link != null) "  ${title}: ${link}\n";
    in
    lib.concatStrings [
      "Arguments are given to the service, except for the arguments in this list.\n"
      (section "Parameters (environment variable, flag):" (
        lib.mapAttrsToList describeParameter process.parameters
      ))
      (section (
        "Configuration files"
        + lib.optionalString (
          configOverrideDir != null
        ) " (mount a file at ${configOverrideDir}/<path> to replace it)"
        + ":"
      ) (map describeFile configFiles))
      (section "Options:" [
        "  --forge-help\n      Show this text.\n"
        "  --\n      Give all next arguments to the service.\n"
      ])
      (section "Upstream references:" (
        describeReference "Command line" process.references.commandLine
        ++ describeReference "Environment variables" process.references.environment
        ++ describeReference "Configuration files" process.references.configFile
      ))
    ]
  );

  parseArgumentsScript = ''
    needValue() {
      if [ "$#" -lt 2 ]; then
        echo ${lib.escapeShellArg "${name}: "}"$1 needs a value" >&2
        exit 64
      fi
    }

    forwarded=()
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --)
          shift
          forwarded+=("$@")
          break
          ;;
        --forge-help)
          ${coreutils}/bin/cat ${help}
          exit 0
          ;;
        ${lib.concatStrings (lib.mapAttrsToList parseFlag flagParameters)}
        *)
          forwarded+=("$1")
          shift
          ;;
      esac
    done
    set -- "''${forwarded[@]}"
  '';

  start = pkgs.writeShellScript "${name}-start" ''
    ${lib.optionalString (process.preStart != null) "${process.preStart} || exit"}
    args=(${lib.escapeShellArg command} ${lib.concatMapStringsSep " " quoteArg process.argv})
    ${lib.concatStrings (lib.mapAttrsToList addFlag flagParameters)}
    set -- "''${args[@]}" "$@"
    echo "Running: $*" >&2
    exec "$@"
  '';

  supervisor = ''
    child=
    stopping=
    trap 'stopping=1; if [ -n "$child" ]; then kill -TERM "$child" 2>/dev/null || true; fi' TERM INT

    # Run the command in the background. The trap cannot run while a foreground
    # command executes. A signal causes `wait` to return before the command stops.
    run() {
      "$@" &
      child=$!
      if [ -n "$stopping" ]; then kill -TERM "$child" 2>/dev/null || true; fi
      while
        wait "$child"
        status=$?
        kill -0 "$child" 2>/dev/null
      do :; done
      child=
      return "$status"
    }

    ${lib.optionalString (setup != "") ''
      run ${pkgs.writeShellScript "${name}-setup" setup}
    ''}
    while [ -z "$stopping" ] && ! run ${start} "$@" && [ -z "$stopping" ]; do
      echo ${lib.escapeShellArg "${name}: service failed, restarting"} >&2
      run ${coreutils}/bin/sleep 1 || true
    done
  '';
in
pkgs.writeShellApplication {
  inherit name;
  text = ''
    ${lib.optionalString parseArguments parseArgumentsScript}
    XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$(${coreutils}/bin/mktemp --directory)}
    export XDG_CONFIG_HOME
    ${lib.concatMapStrings linkConfigFile configFiles}
    ${if supervise then supervisor else "exec ${start} \"$@\""}
  '';
}
