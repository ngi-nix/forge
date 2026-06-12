{
  pkgs,
  ...
}:

{
  apps.rpki-client = {
    displayName = "RPKI Client";
    description = "RPKI relying party software for validating internet routing security data.";
    usage = ''
      rpki-client validates Resource Public Key Infrastructure (RPKI) data,
      helping Internet providers make correct and secure BGP routing decisions.

      #### Show version

      ```bash
      rpki-client -V
      ```

      #### Validate RPKI data (requires TAL files and write access)

      ```bash
      rpki-client -d /var/cache/rpki-client -o /var/db/rpki-client
      ```

      #### Use a specific TAL file

      ```bash
      rpki-client -T /etc/rpki/arin.tal
      ```
    '';

    links = {
      website = "https://www.rpki-client.org";
      source = "https://github.com/rpki-client/rpki-client-portable";
    };

    ngi.grants = {
      Commons = [
        "Erik-RPKI"
      ];
    };

    programs = {
      packages = [
        pkgs.rpki-client
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      rpki-client -V
      rpki-client -n -d /tmp -o /tmp
    '';
  };
}
