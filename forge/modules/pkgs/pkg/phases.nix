{
  lib,
  options,
  specialArgs,
  ...
}@phasesArgs:
{
  imports = [
    (lib.mkAliasOptionModule [ "source" "patches" ] [ "phases" "patch" "patches" ])
  ];
  options.phases = lib.mkOption {
    description = ''
      Package builds are split into phases to make it easier to override specific parts of the build
      (e.g., unpacking the sources or installing the binaries).

      See <https://nixos.org/manual/nixpkgs/stable/#sec-stdenv-phases>.
    '';
    default = { };
    type = lib.types.submoduleWith {
      inherit specialArgs;
      modules =
        let
          phaseModule =
            name:
            ({ config, ... }: {
              options.${name} = lib.mkOption {
                type = lib.types.submoduleWith {
                  inherit specialArgs;
                  modules = [
                    (./phases + "/${name}.nix")
                    {
                      options = {
                        enable = lib.mkOption {
                          type = lib.types.bool;
                          description = "Whether to enable the `${name}` phase.";
                          default = true;
                        };
                        script.pre = lib.mkOption {
                          type = lib.types.lines;
                          default = "";
                          description = ''
                            Bash script to execute at the beginning of the `${name}` phase.

                            Mapped to `pre${lib.toSentenceCase name}`.
                          '';
                        };
                        script.main = lib.mkOption {
                          type = with lib.types; nullOr lines;
                          default = null;
                          description = ''
                            Bash script of the `${name}` phase.

                            Mapped to `${name}Phase`.
                          '';
                          apply =
                            script:
                            if script == null then
                              null
                            else
                              lib.concatStringsSep "\n" [
                                "runHook pre${lib.toSentenceCase name}"
                                script
                                "runHook post${lib.toSentenceCase name}"
                              ];
                        };
                        script.post = lib.mkOption {
                          type = lib.types.lines;
                          default = "";
                          description = ''
                            Bash script to execute at the end of the `${name}` phase.

                            Mapped to `post${lib.toSentenceCase name}`.
                          '';
                        };
                        result.derivationAttrs = options.result.derivationAttrs;
                      };
                    }
                  ];
                };
                default = { };
                description = "The `${name}` phase.";
              };
              config = {
                result.derivationAttrs = lib.mkMerge [
                  config.${name}.result.derivationAttrs
                  (lib.mkIf config.${name}.enable (
                    lib.mkMerge [
                      (lib.mkIf (config.${name}.script.pre != "") {
                        "pre${lib.toSentenceCase name}" = config.${name}.script.pre;
                      })
                      (lib.mkIf (config.${name}.script.post != "") {
                        "post${lib.toSentenceCase name}" = config.${name}.script.post;
                      })
                      (lib.mkIf (config.${name}.script.main != null) {
                        "${name}Phase" = config.${name}.script.main;
                      })
                    ]
                  ))
                ];
              };
            });
        in
        [
          {
            options.result.derivationAttrs = options.result.derivationAttrs;
          }
          (phaseModule "build")
          (phaseModule "check")
          (phaseModule "configure")
          (phaseModule "dist")
          (phaseModule "fixup")
          (phaseModule "install")
          (phaseModule "installCheck")
          (phaseModule "patch")
          (phaseModule "unpack")
        ];
    };
  };
  config.result.derivationAttrs = phasesArgs.config.phases.result.derivationAttrs;
}
