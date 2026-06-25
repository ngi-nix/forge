{
  config,
  lib,
  pkgs,
  ...
}:
let
  exampleKsy = builtins.readFile ./gif_header.ksy;

  # 1x1 gif from http://probablyprogramming.com/2009/03/15/the-tiniest-gif-ever
  gifBase64 = "R0lGODlhAQABAIABAP///wAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==";
  tinyGif = pkgs.runCommand "tiny.gif" { } ''
    echo "${gifBase64}" | ${pkgs.coreutils}/bin/base64 -d > $out
  '';

  mainInstructions = lib.trim ''
    kaitai-struct-compiler --target python gif_header.ksy

    python -c '
    from gif import Gif
    g = Gif.from_file("sample.gif")

    print(f"width = {g.logical_screen.image_width}")
    print(f"height = {g.logical_screen.image_height}")
    '
  '';
in
{
  apps.kaitai-struct = {
    displayName = "Kaitai Struct";
    description = "A new way to develop parsers for binary structures.";
    usage = ''
      Kaitai Struct is a declarative language used to describe various binary data structures, laid out in files or in memory: i.e. binary file formats, network stream packet formats, etc.

      Kaitai Struct tries to make the job of reading binary data structures from files or network streams and representing them in memory for access, easier — you only have to describe the binary format once and then everybody can use it from their programming languages — cross-language, cross-platform.

      #### Quick Start

      ```yaml
      ${exampleKsy}
      ```

      Consider the simple `.ksy` format description above, which describes the header of a GIF image file.

      It declares that a GIF file usually has a `.gif` extension and uses little-endian integer encoding. The file itself starts with two blocks: first comes `header` and then comes `logical_screen`:

      - "Header" consists of a "magic" string of 3 bytes ("GIF") that identifies that it’s a GIF file starting and then there are 3 more bytes that identify the format version (87a or 89a).
      - "Logical screen descriptor" is a block of integers:
        - `image_width` and `image_height` are 2-byte unsigned ints
        - `flags`, `bg_color_index` and `pixel_aspect_ratio` take 1-byte unsigned ints each

      This `.ksy` file can be compiled into `gif.cpp` / `Gif.cs` / `gif.go` / `Gif.java` / `Gif.js` / `gif.lua` / `gif.nim` / `Gif.pm` / `Gif.php` / `gif.py` / `gif.rb` / `gif.rs` and then one can instantly load a `.gif` file and access, for example, its width and height.

      Enter a temporary directory.

      ```bash
      mkdir test && cd test
      ```

      Enter the nix shell for this project. (See [Run](app/kaitai-struct#run) instructions.)

      Save the file above in `gif_header.ksy`.

      Get a sample gif from somewhere (eg. [https://en.wikipedia.org/wiki/GIF](https://en.wikipedia.org/wiki/GIF)).

      ```bash
      wget https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif -O sample.gif
      ```

      This shell environment provides python with `kaitaistruct` python package pre-installed.

      ```bash
      ${mainInstructions}
      ```

      This example shows only a very limited subset of what Kaitai Struct can do. Please refer to the [documentation](${config.apps.kaitai-struct.links.docs}) and try the online [ide](https://ide.kaitai.io), which has many examples.
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [ "Kaitai-64bit" ];
      Entrust = [ "Kaitai-Rust" ];
      Review = [ "Kaitai-Serialization" ];
    };

    links = {
      source = "https://github.com/kaitai-io/kaitai_struct";
      docs = "https://doc.kaitai.io";
      website = "https://kaitai.io";
    };

    programs = {
      packages = [
        pkgs.kaitai-struct-compiler
        (pkgs.python3.withPackages (
          ps: with ps; [
            kaitaistruct
          ]
        ))
        pkgs.wget
      ];
      runtimes.shell.enable = true;
    };

    test.programs.script =
      let
        mainScript = pkgs.writeShellApplication {
          name = "script";
          text = mainInstructions;
        };
      in
      ''
        cp ${tinyGif} sample.gif
        cp ${./gif_header.ksy} gif_header.ksy
        ${mainScript}/bin/script | grep -q 'width = 1'
      '';
  };
}
