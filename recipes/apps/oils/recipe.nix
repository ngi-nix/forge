{
  config,
  pkgs,
  ...
}:

{
  apps.oils = {
    displayName = "Oils";
    description = "Bringing shell environments into the 21st century.";
    usage = ''
      Oil is a new Unix shell.

      [OSH](https://oils.pub/osh.html) runs your existing shell scripts.

      ```bash
      set -u
      echo "hello $oops"
                  ^~~~~
      fatal: Undefined variable 'oops'
      ```

      [YSH](https://oils.pub/ysh.html) is for Python and JavaScript users who avoid shell!

      ```bash
      ysh$ echo '{"shell": "ysh", "fun": true}' >x.json
      ysh$ json read < x.json
      ysh$ = _reply
      (Dict)   {shell: 'ysh', fun: true}
      ```

      ##### Examples

      `osh` is compatible with POSIX shell, bash, and other shells.

      ```bash
      osh -c 'echo hi'
      osh myscript.sh
      echo 'echo hi' | osh
      ```

      ###### shell-flags

      `osh` and `ysh` accept standard POSIX shell flags, like:

      ```bash
      osh -o errexit -c 'false'
      ysh -n myfile.ysh
      ysh +o errexit -c 'false; echo ok'
      ```

      See also [Documentation](${config.apps.oils.links.docs}), [FAQ](https://www.oilshell.org/blog/tags.html#FAQ) and [oils wiki](https://github.com/oils-for-unix/oils/wiki).
    '';

    ngi.grants = {
      Commons = [ "OSH-everywhere" ];
      Entrust = [ "Oils" ];
    };

    links = {
      website = "https://oils.pub";
      source = "https://github.com/oils-for-unix/oils";
      docs = "https://oils.pub/release/latest/doc/published.html";
    };

    programs = {
      packages = [ pkgs.oils-for-unix ];
      runtimes.shell.enable = true;
    };

    # Test every command mentioned in the usage above.
    test.programs.script = ''
      osh -c 'echo "hello $oops"' | grep -q "hello "
      osh -c 'set -u; echo "hello $oops"' >fatal 2>&1 || true
      grep -q "fatal" fatal
      echo '{"shell": "ysh", "fun": true}' >x.json
      ysh -c 'json read < x.json; = _reply' | grep -q "Dict"

      osh -c 'echo hi' | grep -q "hi"
      echo 'echo hi' | osh | grep -q "hi"
      osh -o errexit -c 'false' || echo fail | grep -q fail
      ysh +o errexit -c 'false; echo ok' | grep -q "ok"
    '';
  };
}
