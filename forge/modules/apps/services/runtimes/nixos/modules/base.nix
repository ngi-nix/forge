{
  app,
  ...
}:
{
  networking.hostName = app.name;

  system.stateVersion = "25.11";
}
