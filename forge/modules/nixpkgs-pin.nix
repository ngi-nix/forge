{ lib }:
rec {
  submodule = lib.types.submodule {
    options = {
      rev = lib.mkOption {
        type = lib.types.str;
        description = "Git commit revision from NixOS/nixpkgs.";
        example = "2795c506fe8fb7b03c36ccb51f75b6df0ab2553f";
      };
      narHash = lib.mkOption {
        type = lib.types.str;
        description = "NAR hash of the pinned Nixpkgs tree.";
        example = "sha256-W7lqHp0qZiENCDwUZ5EX/lNhxjMdNapFnbErcbnP11Q=";
      };
      owner = lib.mkOption {
        type = lib.types.str;
        default = "NixOS";
        description = "GitHub organization or user owning the repository.";
        example = "NixOS";
      };
      repo = lib.mkOption {
        type = lib.types.str;
        default = "nixpkgs";
        description = "Repository name.";
        example = "nixpkgs";
      };
      ref = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional Git branch or tag name.";
        example = "nixos-unstable";
      };
      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Direct Git URL to use instead of GitHub.";
        example = "https://git.example.com/custom/nixpkgs.git";
      };
      date = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Date of the pinned revision (format: `YYYY-MM-DD`).";
        example = "2026-10-04";
      };
      reason = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Human-readable reason explaining why this is pinned to this Nixpkgs revision.";
        example = "Pinned to last working revision before upstream regression.";
      };
    };
  };

  option = lib.mkOption {
    type = lib.types.nullOr submodule;
    default = null;
    description = ''
      Pin to a specific Nixpkgs revision using `builtins.fetchTree`.
      Avoids adding transitive inputs to `flake.lock`.
    '';
    example = lib.literalExpression ''
      {
        rev = "2795c506fe8fb7b03c36ccb51f75b6df0ab2553f";
        narHash = "sha256-W7lqHp0qZiENCDwUZ5EX/lNhxjMdNapFnbErcbnP11Q=";
        date = "2025-05-20";
        reason = "Pinned to last working release.";
      }
    '';
  };

  fetchTree =
    pin:
    if pin.url != null then
      builtins.fetchTree {
        type = "git";
        url = pin.url;
        inherit (pin) rev narHash;
      }
    else
      builtins.fetchTree (
        {
          type = "github";
          inherit (pin)
            owner
            repo
            rev
            narHash
            ;
        }
        // lib.optionalAttrs (pin.ref != null) {
          inherit (pin) ref;
        }
      );

  mkEffectivePkgs =
    {
      pin,
      basePkgs,
      system ? basePkgs.stdenv.hostPlatform.system,
    }:
    if pin != null then
      let
        tree = fetchTree pin;
        cleanConfig = builtins.removeAttrs (basePkgs.config or { }) [ "replaceStdenv" ];
        imported = import tree {
          inherit system;
          config = cleanConfig;
          overlays = [ ];
        };
      in
      imported
      // {
        pkgsOriginal = imported;
      }
    else
      basePkgs;

  mkPinWarning =
    {
      entityType,
      name,
      pin,
    }:
    lib.optional (pin != null) {
      condition = true;
      message = "${entityType} '${name}' is ${
        if entityType == "App" then "running" else "built"
      } using a pinned Nixpkgs revision (${pin.rev}${
        lib.optionalString (pin.date != null) " from ${pin.date}"
      })${lib.optionalString (pin.reason != null) ": ${pin.reason}"}.";
    };

  mkBrokenWarning =
    {
      entityType,
      name,
      broken,
      lastWorkingVersion,
    }:
    lib.optional broken {
      condition = true;
      message = "${entityType} '${name}' is marked broken.${
        lib.optionalString (lastWorkingVersion != null) " Last working version: ${lastWorkingVersion}."
      }";
    };
}
