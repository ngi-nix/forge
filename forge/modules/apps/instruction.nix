{
  lib,
  ...
}:
{
  options = {
    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        The description for the instruction to take, it is displayed to the user above the command.

        To have an instruction just contain a description, do not set `command` or `altCommand`.
      '';
    };

    command = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The command to execute in the test script.
        This will be shown to the user if `altCommand` is null.
      '';
    };

    altCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        This is shown to the user in-place of `command` if it is defined.
        We use it to hide logic that we do not want to show to the user, e.g. creating
        a file with `cat <<EOF` before executing a command dependent on that file.

        To do this, set `command` to be the thing you want shown to the user, and set
        `altCommand` to the required logic.
      '';
    };
  };
}
