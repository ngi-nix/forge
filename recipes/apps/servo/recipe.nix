{
  pkgs,
  ...
}:

{
  apps.servo = {
    displayName = "Servo";
    description = "Embeddable, independent, memory-safe, modular, parallel web rendering engine.";
    usage = ''
      Servo is a web rendering engine written in Rust, designed to be safe,
      modular, and embeddable in other applications.

      Open a URL in Servo

      ```bash
      servoshell https://servo.org
      ```
    '';

    icon = ./icon.svg;

    links = {
      website = "https://servo.org";
      source = "https://github.com/servo/servo";
    };

    ngi.grants = {
      Entrust = [
        "Servo"
        "Servo-CSS"
      ];
      Core = [
        "Servo-Benchmark"
        "Servo-Script"
        "Servo-Multiprocess"
      ];
      Review = [
        "Servo-DX"
        "Servo-Multibrowsing"
      ];
      Commons = [
        "Servo-ServiceWorker-WebAPI"
        "Servo-Editability"
      ];
    };

    programs = {
      packages = [
        pkgs.servo
      ];
      mainPackage = pkgs.servo;

      runtimes.shell = {
        enable = true;
      };
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      servoshell --version 2>&1 | grep -qE "[0-9]+\.[0-9]+"
    '';
  };
}
