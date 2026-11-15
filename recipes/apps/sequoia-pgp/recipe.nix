{
  forge-lib,
  lib,
  pkgs,
  ...
}:

{
  apps.sequoia-pgp = {
    displayName = "Sequoia PGP";
    description = "Command-line OpenPGP tool with post-quantum cryptography support.";
    categories = with forge-lib.categories; [
      Security
    ];
    usage = ''
      Sequoia PGP (`sq`) is a command-line OpenPGP tool with post-quantum
      cryptography support, implementing draft-ietf-openpgp-pqc.

      #### Generate a key

      ```bash
      sq key generate --own-key --name 'alice' --email 'alice@example.com'
      ```

      #### Encrypt a file

      ```bash
      sq encrypt --recipient-cert alice.pgp message.txt
      ```

      #### Decrypt a file

      ```bash
      sq decrypt --recipient-key alice.key message.txt.pgp
      ```

      #### Sign a file

      ```bash
      sq sign --signer-key alice.key message.txt
      ```
    '';

    links = {
      website = "https://sequoia-pgp.org";
      source = "https://gitlab.com/sequoia-pgp/sequoia-sq";
    };

    ngi.grants = {
      Review = [
        "Sequoia-Keystore"
        "Sequoia-TPM"
        "Sequoia-commandline"
        "SequoiaChameleon"
      ];
      Commons = [
        "MachineReadable-sq"
        "Sequoia-PQC"
      ];
    };

    programs = {
      packages = [
        pkgs.sequoia-pgp
      ];

      runtimes.shell.enable = true;
      runtimes.browser = {
        enable = true;
        wasmPackage =
          let
            wasi = pkgs.pkgsCross.wasi32.pkgsOriginal;
            sqop = pkgs.pkgsOriginal.sequoia-sqop;
          in
          # `sq` needs the network, a key store and SQLite.
          # `sqop` is the Stateless OpenPGP program of Sequoia, which needs none of these.
          wasi.rustPlatform.buildRustPackage {
            pname = "sqop";
            inherit (sqop) version src cargoDeps;
            # Nettle does not compile for WASI, thus use the cryptography in Rust.
            # Sequoia accepts this backend only with these two features.
            buildNoDefaultFeatures = true;
            buildFeatures = [
              "cli"
              "crypto-rust"
              "sequoia-openpgp/allow-experimental-crypto"
              "sequoia-openpgp/allow-variable-time-crypto"
            ];
            nativeBuildInputs = [ pkgs.pkg-config ];
            # The tests do not run on the build platform.
            doCheck = false;
            # Link with the C compiler of the WASI toolchain, not with `rust-lld`.
            env.RUSTFLAGS = "-Clinker-flavor=gcc -Clink-self-contained=no -Clink-arg=--target=${wasi.stdenv.targetPlatform.config}";
            meta = sqop.meta // {
              mainProgram = "sqop";
              platforms = lib.platforms.wasi;
            };
          };
        # Make a key with post-quantum cryptography.
        args = "generate-key --profile security 'Alice <alice@example.org>'";
      };
    };
  };
}
