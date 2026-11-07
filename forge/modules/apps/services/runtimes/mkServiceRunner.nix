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
    XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$(${coreutils}/bin/mktemp --directory)}
    export XDG_CONFIG_HOME
    ${lib.concatMapStrings linkConfigFile configFiles}
    ${if supervise then supervisor else "exec ${start} \"$@\""}
  '';
}
