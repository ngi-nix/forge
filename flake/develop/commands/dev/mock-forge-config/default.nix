{
  pkgs ? import <nixpkgs> { },
}:
(pkgs.writers.writePython3Bin "mock-forge-config" {
  libraries = [ pkgs.python3.pkgs.faker ];
} (builtins.readFile ./generate.py)).overrideAttrs
  {
    meta.description = "Helper script for UI tests to generate mock backend json";
  }
