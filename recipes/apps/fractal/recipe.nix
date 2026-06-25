{
  pkgs,
  ...
}:

{
  apps.fractal = {
    displayName = "Fractal";
    description = "Native client for the Matrix protocol.";
    usage = ''
      Fractal is a Matrix messaging app for GNOME written in Rust. Its interface is optimized for collaboration in large groups, such as free software projects, and will fit all screens, big or small.

      See also [Security best practices](https://gitlab.gnome.org/World/fractal#security-best-practices).
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Review = [ "Fractal" ];
    };

    links = {
      docs = "https://world.pages.gitlab.gnome.org/fractal";
      source = "https://gitlab.gnome.org/World/fractal";
    };

    programs = {
      mainPackage = pkgs.fractal;
      runtimes.program.enable = true;
    };
  };
}
