{
  lib,
  ...
}:

{
  apps.example = {
    description = lib.mkForce "Example application demonstrating multiple Forge runtimes (extended).";
  };
}
