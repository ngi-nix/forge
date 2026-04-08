{
  writers,
  python3,
}:
let
  devUIDir = builtins.toString ../dev-ui;
in
(writers.writePython3Bin "mock-forge-config" {
  libraries = [ python3.pkgs.faker ];
  flakeIgnore = [
    "E402"
    "E501"
  ];
} (builtins.replaceStrings [ "@devUIDir@" ] [ devUIDir ] (builtins.readFile ./generate.py)))
.overrideAttrs
  {
    meta.description = "Helper script for UI tests to generate mock backend json";
  }
