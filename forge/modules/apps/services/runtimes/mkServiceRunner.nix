# Build the executable that starts a service component.
#
# The executable puts `process.configData` into `$XDG_CONFIG_HOME` (a new
# temporary directory if the variable is not set), runs
# `process.preStart` and then runs `process.command`.
#
# The service gets `process.argv` as double-quoted shell words. Thus, `$VAR` and
# `${VAR}` expand at service start and each item stays one argument. `$$` is a
# literal `$`. Other shell syntax has no special meaning.
{
  lib,
  pkgs,
  name,
  service,
  setup ? "",
  # Set to `true` if no service manager controls the process, for example in a
  # container. The executable then runs `setup` one time, restarts the service
  # after a failure and forwards termination signals to the service. It also
  # collects orphaned processes when it runs as PID 1.
  supervise ? false,
}:
let
  inherit (service) process;
  inherit (process) command;

  esc = lib.escapeShellArg;

  enabledConfigFiles = lib.filter (file: file.enable) (lib.attrValues process.configData);

  # `"${file.source}"` copies a path value to the store. `toString` does not.
  linkConfigFile = file: ''
    echo ${esc "Config: ${file.path} -> ${file.source}"} >&2
    mkdir --parents "$XDG_CONFIG_HOME"/${esc (dirOf file.path)}
    ln --symbolic --force ${esc "${file.source}"} "$XDG_CONFIG_HOME"/${esc file.path}
  '';

  setupScript = pkgs.writeShellScript "${name}-setup" setup;

  quoteArg =
    arg:
    ''"${lib.replaceStrings [ "\\" "\"" "`" "$(" "$$" ] [ "\\\\" "\\\"" "\\`" "\\$(" "\\$" ] arg}"'';

  startScript = pkgs.writeShellScript "${name}-start" ''
    command=${esc (if lib.isDerivation command then lib.getExe command else command)}
    args=(${lib.concatMapStringsSep " " quoteArg process.argv})

    ${lib.optionalString (process.preStart != null) "${process.preStart} || exit"}
    echo "Running: $command ''${args[*]}" >&2
    exec "$command" "''${args[@]}"
  '';

  runSupervisor = ''
    child=
    stopping=

    kill_child() {
      kill -TERM "$child" 2>/dev/null || true
    }

    stop_child() {
      stopping=1
      if [ -n "$child" ]; then
        kill_child
      fi
    }
    trap stop_child TERM INT

    # Run the command in the background. The trap cannot run while a foreground
    # command executes.
    run() {
      "$@" &
      child=$!

      # A signal that came before `child` was set did not stop the command.
      if [ -n "$stopping" ]; then
        kill_child
      fi

      # A signal causes `wait` to return before the command stops. `kill -0`
      # is successful while the command runs. Thus, the loop waits again until
      # the command stops, and `status` is the exit status of the command.
      while
        wait "$child"
        status=$?
        kill -0 "$child" 2>/dev/null
      do :; done

      child=
      return "$status"
    }

    ${lib.optionalString (setup != "") ''
      run ${setupScript}
    ''}

    # Restart the service after each failure. The first `stopping` test
    # prevents a start after a signal that came during `setup` or `sleep`.
    # The second test prevents a restart of a service that the signal stopped.
    while [ -z "$stopping" ] && ! run ${startScript} && [ -z "$stopping" ]; do
      echo "${name}: service failed, restarting" >&2
      run sleep 1 || true
    done
  '';
in
pkgs.writeShellApplication {
  inherit name;
  runtimeInputs = [ pkgs.coreutils ];
  text = ''
    XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$(mktemp --directory)}
    export XDG_CONFIG_HOME
    ${lib.concatMapStrings linkConfigFile enabledConfigFiles}
    ${if supervise then runSupervisor else "exec ${startScript}"}
  '';
}
