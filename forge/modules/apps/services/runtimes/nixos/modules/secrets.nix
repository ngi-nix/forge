# Secrets of the service components, loaded with systemd's `LoadCredential`.
#
# Each secret is a NixOS option, which deployments set to a secret file
# (e.g. from agenix or sops-nix). By default, the option is a Nix store file
# with the insecure default value of the secret.
{
  app,

  lib,
  ...
}:
{ config, ... }:
let
  cfg = config.forge.apps.${app.name};

  componentsWithSecrets = lib.filterAttrs (
    _: component: component.secrets != { }
  ) app.services.components;

  insecureSecrets = lib.concatLists (
    lib.mapAttrsToList (
      componentName: component:
      lib.mapAttrsToList (secretName: _: { inherit componentName secretName; }) (
        lib.filterAttrs (
          secretName: secret: cfg.secrets.${componentName}.${secretName} == "${secret.defaultFile}"
        ) component.secrets
      )
    ) componentsWithSecrets
  );

  showSecrets = f: lib.concatMapStringsSep "\n" f insecureSecrets;
in
{
  options.forge.apps.${app.name} = {
    secrets = lib.mapAttrs (
      componentName: component:
      lib.mapAttrs (
        secretName: secret:
        lib.mkOption {
          type = lib.types.strMatching "/.*";
          default = "${secret.defaultFile}";
          defaultText = lib.literalMD "Nix store file with the insecure default value";
          description = ''
            Absolute path to the file with the `${secretName}` secret of the `${componentName}` service.

            Set it to a file which is not in the Nix store, for example from agenix or sops-nix.
          '';
          example = "/run/agenix/${app.name}-${secretName}";
        }
      ) component.secrets
    ) componentsWithSecrets;

    useDefaultSecrets = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      default = false;
      description = ''
        Whether the insecure default values of the secrets are used on purpose
        (e.g. in the NixOS VM and in tests), without a warning.
      '';
    };
  };

  config = {
    systemd.services = lib.mapAttrs (componentName: component: {
      serviceConfig.LoadCredential = lib.mapAttrsToList (
        secretName: _: "${secretName}:${cfg.secrets.${componentName}.${secretName}}"
      ) component.secrets;
    }) componentsWithSecrets;

    warnings = lib.optional (!cfg.useDefaultSecrets && insecureSecrets != [ ]) ''
      ngi-forge: ${app.name}: the application uses insecure default values of the secrets:

      ${showSecrets (s: "- ${s.componentName}.${s.secretName}")}

      See https://ngi.nixos.org/docs/manuals/user/deployment.html#application-secrets
      how to manage the secrets properly.
    '';
  };
}
