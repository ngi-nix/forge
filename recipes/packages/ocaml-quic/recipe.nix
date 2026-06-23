{ lib, ... }:

{
  packages.ocaml-quic = {
    version = "0-unstable-2026-03-16";
    description = "Implement QUIC/QUIC-TLS/QPACK and HTTP/3 in OCAML";
    license = lib.licenses.bsd3;

    source = {
      git = "github:anmonteiro/ocaml-quic/baaa52e72346027332882aa3a5d5affe04e24abc";
      hash = "sha256-7Fn379yEDdGVrg+5QMe7QMqGpq2986r/fs+8SepIYp4=";
    };

    build.ocamlBuilder = {
      enable = true;
    };
  };
}
