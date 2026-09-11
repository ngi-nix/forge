{
  lib,
  pkgs,
  ...
}:

{
  pkgs.lib25519 = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.lib25519;
    };
  };

  apps.lib25519 = {
    displayName = "lib25519";
    description = "Microlibrary for X25519/Ed25519 cryptography.";
    categories = with lib.categories; [ Security ];
    usage = ''
      #### Intro

      _lib25519_ is a microlibrary for the X25519 encryption system and the
      Ed25519 signature system, both of which use the Curve25519 elliptic
      curve. Curve25519 is the fastest curve in TLS 1.3, and the only curve in
      Wireguard, Signal, and many other applications (see Nicolai Brown's page
      <https://ianix.com/pub/curve25519-deployment.html>).

      _lib25519_ has a very simple stateless
      [API](https://lib25519.cr.yp.to/api.html) based on the SUPERCOP API, with
      wire-format inputs and outputs, providing functions that directly match
      the central cryptographic operations in X25519 and Ed25519:

      - `lib25519_dh_keypair(pk,sk)`: X25519 key generation
      - `lib25519_dh(k,pk,sk)`: shared-secret generation
      - `lib25519_sign_keypair(pk,sk)`: Ed25519 key generation
      - `lib25519_sign(sm,&smlen,m,mlen,sk)`: signing
      - `lib25519_sign_open(m,&mlen,sm,smlen,pk)`: verification + message recovery

      Internally, _lib25519_ includes implementations designed for
      [performance](https://lib25519.cr.yp.to/speed.html) on various CPUs,
      implementations designed to work portably across CPUs, and automatic
      run-time selection of implementations.

      _lib25519_ is intended to be called by larger multi-function libraries,
      including libraries in other languages via FFI. The idea is that _lib25519_
      will take responsibility for the details of X25519/Ed25519 computation,
      including optimization, timing-attack protection, and eventually
      verification, freeing up the calling libraries to concentrate on
      application-specific needs such as protocol integration. Applications can
      also call _lib25519_ directly.

      #### Find Out More

      By visiting the project's [homepage](https://lib25519.cr.yp.to).
    '';

    links = {
      docs = "https://lib25519.cr.yp.to";
      source = "https://lib25519.cr.yp.to/download.html";
      website = "https://lib25519.cr.yp.to";
    };

    ngi.grants = {
      Core = [
        "lib25519-ARM64"
      ];
      Entrust = [
        "lib25519-ARM"
      ];
      Review = [
        "lib25519"
      ];
    };

    programs = {
      runtimes.shell.enable = true;
      packages = [
        pkgs.lib25519
      ];
    };

    test.programs.script = ''
      lib25519-speed
    '';
  };
}
