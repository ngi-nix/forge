# Secrets of the service components, loaded with systemd's `LoadCredential`.
#
# Each secret is a NixOS option, which deployments set to a secret file
# (e.g. from agenix or sops-nix). By default, the option is the `file` of the
# secret in the recipe, or a Nix store file with its insecure default value.
{
  app,

  lib,
  ...
}:
{ config, ... }:
let
  cfg = config.forge.apps.${app.name};

  componentsWithSecrets = lib.filterAttrs (
    _: service: service.secrets != { }
  ) app.services.components;

  insecureSecrets = lib.concatLists (
    lib.mapAttrsToList (
      componentName: service:
      lib.mapAttrsToList (secretName: _: { inherit componentName secretName; }) (
        lib.filterAttrs (
          secretName: secret: cfg.secrets.${componentName}.${secretName} == "${secret.defaultFile}"
        ) service.secrets
      )
    ) componentsWithSecrets
  );

  showSecrets = f: lib.concatMapStringsSep "\n" f insecureSecrets;
in
{
  options.forge.apps.${app.name} = {
    secrets = lib.mapAttrs (
      componentName: service:
      lib.mapAttrs (
        secretName: secret:
        lib.mkOption {
          type = lib.types.str;
          default = if cfg.useDefaultSecrets then "${secret.defaultFile}" else secret.path;
          defaultText = lib.literalMD "`file` of the secret in the recipe, or a Nix store file with the insecure default value";
          description = ''
            Path to the file with the `${secretName}` secret of the `${componentName}` service.

            Set it to a file which is not in the Nix store, for example from agenix or sops-nix.
          '';
          example = "/run/agenix/${app.name}-${secretName}";
        }
      ) service.secrets
    ) componentsWithSecrets;

    allowInsecureSecrets = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to allow the insecure default values of the secrets without a warning.
      '';
    };

    useDefaultSecrets = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      default = false;
      description = ''
        Whether to use the insecure default values of the secrets,
        also when the recipe sets their `file`
        (e.g. in the NixOS VM and in tests, where the files do not exist).
      '';
    };
  };

  config = {
    systemd.services = lib.mapAttrs (componentName: service: {
      serviceConfig.LoadCredential = lib.mapAttrsToList (
        secretName: _: "${secretName}:${cfg.secrets.${componentName}.${secretName}}"
      ) service.secrets;
    }) componentsWithSecrets;

    warnings =
      lib.optional (!cfg.allowInsecureSecrets && !cfg.useDefaultSecrets && insecureSecrets != [ ])
        ''
          ngi-forge: ${app.name}: the application uses insecure default values of the secrets:

          ${showSecrets (s: "- ${s.componentName}.${s.secretName}")}

          The default values are stored in the Nix store and are readable by all users.
          Create the secret files with agenix (https://github.com/ryantm/agenix)
          or sops-nix (https://github.com/Mic92/sops-nix), and set them in the application configuration:

          forge.apps.${app.name} = {
          ${showSecrets (
            s:
            "  services.components.${s.componentName}.secrets.${s.secretName}.file = \"/path/to/secret-file\";"
          )}
          };

          or in the NixOS configuration:

          ${showSecrets (
            s: "forge.apps.${app.name}.secrets.${s.componentName}.${s.secretName} = \"/path/to/secret-file\";"
          )}

          See https://ngi.nixos.org/docs/manuals/user/deployment.html#application-secrets for details.
        '';
  };
}
