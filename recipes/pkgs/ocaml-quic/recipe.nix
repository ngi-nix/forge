{
  config,
  lib,
  pkgs,
  ...
}:

let
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages.overrideScope (
    _: prev: {
      ssl = prev.ssl.overrideAttrs {
        src = pkgs.fetchFromGitHub {
          owner = "savonet";
          repo = "ocaml-ssl";
          rev = "a3ec4b6d6883a6a73e59f6756eceb1b7cbf45183";
          hash = "sha256-zXk5cV6lz5q6XX/CVk8ymt/o+J8DCgAqWMULJLPzenk=";
        };
      };

      tls = prev.tls.overrideAttrs {
        src = pkgs.fetchFromGitHub {
          owner = "anmonteiro";
          repo = "ocaml-tls";
          rev = "7756b79fd7ecd74bb516a01e054f08ddf031ebf1";
          hash = "sha256-nKAqSI4JHfgAxd+UQrtW/FZIPI7XC0YOycG/j1AZoxU=";
        };
      };
    }
  );
in
{
  pkgs.quic = {
    version = "0-unstable-2026-03-16";
    description = "Implement QUIC/QUIC-TLS/QPACK and HTTP/3 in OCAML.";
    homePage = "https://github.com/anmonteiro/ocaml-quic";
    license = lib.licenses.bsd3;

    source = {
      git = "github:anmonteiro/ocaml-quic/baaa52e72346027332882aa3a5d5affe04e24abc";
      hash = "sha256-7Fn379yEDdGVrg+5QMe7QMqGpq2986r/fs+8SepIYp4=";
    };

    build.ocamlBuilder = {
      enable = true;

      ocamlPackages = _: ocamlPackages;

      packages = {
        build = [ pkgs.pkg-config ];

        run = [
          ocamlPackages.dune-configurator
          pkgs.openssl
        ];

        dependencies = with ocamlPackages; [
          digestif
          faraday
          hex
          kdf
          mirage-crypto
          psq
          ssl
          tls
          x509
        ];
      };
    };
    phases = {
      # FixMe(buildability): fails
      check.enable = false;
    };
  };

  pkgs.qpack = {
    description = "QPACK header compression for HTTP/3 in OCaml.";
    inherit (config.pkgs.quic)
      source
      version
      homePage
      license
      ;

    build.ocamlBuilder = {
      enable = true;
      packages.dependencies = with ocamlPackages; [
        angstrom
        faraday
        psq
      ];
    };

    phases = {
      # FixMe(buildability): fails
      check.enable = false;
    };
  };

  pkgs.h3 = {
    description = "HTTP/3 implementation in OCaml.";
    inherit (config.pkgs.quic)
      source
      version
      homePage
      license
      ;

    build.ocamlBuilder = {
      enable = true;
      packages.dependencies = with ocamlPackages; [
        angstrom
        faraday
        httpaf

        pkgs.qpack
        pkgs.quic
      ];
    };

    phases = {
      check = {
        /*
          FixMe(buildability): fails with:
          ocaml5.4.1-h3> File "lib_test/test_parser.ml", line 86, characters 26-32:
          ocaml5.4.1-h3> 86 |               ; payload = "abcd"
          ocaml5.4.1-h3>                                ^^^^^^
          ocaml5.4.1-h3> Error: This constant has type string but an expression was expected of type
          ocaml5.4.1-h3>          Quic.Frame.payload
          […]
          ocaml5.4.1-h3> File "lib_test/test_flow_control.ml", line 179, characters 40-42:
          ocaml5.4.1-h3> 179 |     { Frame.off = 0; len = 0; payload = ""; payload_off = 0 }
          ocaml5.4.1-h3>                                               ^^
          ocaml5.4.1-h3> Error: This constant has type string but an expression was expected of type
          ocaml5.4.1-h3>          Quic.Frame.payload
          […]
          ocaml5.4.1-h3> File "lib_test/test_packet_protection.ml", line 662, characters 53-60:
          ocaml5.4.1-h3> 662 |           ; fragment = { off = 0; len = 5; payload = "hello"; payload_off = 0 }
          ocaml5.4.1-h3>                                                            ^^^^^^^
          ocaml5.4.1-h3> Error: This constant has type string but an expression was expected of type
          ocaml5.4.1-h3>          Quic.Frame.payload
        */
        enable = false;
        packages.host.target = with ocamlPackages; [
          alcotest
          hex
          mirage-crypto-rng
          tls
          pkgs.quic
          yojson
        ];
      };
    };
  };

  pkgs.quic-lwt = {
    description = "Lwt runtime for the OCaml QUIC implementation.";
    inherit (config.pkgs.quic)
      source
      version
      homePage
      license
      ;

    build.ocamlBuilder = {
      enable = true;
      packages.dependencies = with ocamlPackages; [
        hex
        lwt
        gluten

        pkgs.quic
      ];
    };

    phases = {
      # FixMe(buildability): fails
      check.enable = false;
    };
  };

  pkgs.quic-eio = {
    description = "Eio runtime for the OCaml QUIC implementation.";
    inherit (config.pkgs.quic)
      source
      version
      homePage
      license
      ;

    build.ocamlBuilder = {
      enable = true;
      packages.dependencies = with ocamlPackages; [
        eio
        eio_posix
        gluten-eio
        hex

        pkgs.quic
      ];
    };

    phases = {
      # FixMe(buildability): fails
      check.enable = false;
    };
  };
}
