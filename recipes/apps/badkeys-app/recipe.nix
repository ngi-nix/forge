{
  pkgs,
  ...
}:
{
  apps.badkeys = {
    displayName = "badkeys";
    description = "Checking cryptographic public keys for known vulnerabilities.";
    usage = ''
      Download blocklist metadata.

      ```bash
      badkeys --update-bl
      ```

      Test on your ssh public keys. Should output `ok`.

      ```bash
      badkeys -v ~/.ssh/*.pub
      ```

      Test on a known vulerable key. (key obtained from badkeys homepage. SMALL KEY)

      ```bash
      cat <<EOF >smallkey.pub
      -----BEGIN RSA PUBLIC KEY-----
      MEgCQQDf3ZUn4aBDoJdJ6dJM1X0pZlz8LWf9QD0wYsB9rAahvoSNN3JVi+xRBiI/
      7UDBtWAqeun5h44V43Rx9QJVlPYdAgMBAAE=
      -----END RSA PUBLIC KEY-----
      EOF

      badkeys -w smallkey.pub
      ```

      See the homepage for many more kinds of keys badkeys can detect.
    '';

    icon = ./icon.svg;

    links = {
      website = "https://badkeys.info";
      source = "https://github.com/badkeys/badkeys";
    };

    ngi.grants = {
      Core = [ "badkeys" ];
    };

    programs = {
      packages = [
        pkgs.badkeys
        pkgs.openssl
      ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      set -x
      openssl genrsa -out file.key
      badkeys -c rsawarnings -v file.key | grep -q 'ok'

      cat <<EOF >smallkey.pub
      -----BEGIN RSA PUBLIC KEY-----
      MEgCQQDf3ZUn4aBDoJdJ6dJM1X0pZlz8LWf9QD0wYsB9rAahvoSNN3JVi+xRBiI/
      7UDBtWAqeun5h44V43Rx9QJVlPYdAgMBAAE=
      -----END RSA PUBLIC KEY-----
      EOF

      badkeys -c rsawarnings -w smallkey.pub > result.txt || true
      grep -q 'vulnerability' result.txt
      set +x
    '';
  };
}
