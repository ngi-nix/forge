{
  lib,
  ...
}:

{
  apps.himalaya = {
    description = lib.mkForce "Custom application description.";
  };
}
