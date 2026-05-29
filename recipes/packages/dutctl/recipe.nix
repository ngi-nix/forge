{
  lib,
  pkgs,
  ...
}:

{
  packages.dutctl = {
    version = "0-unstable-2026-05-21";
    description = "Unified device management for open firmware development.";
    homePage = "https://github.com/BlindspotSoftware/dutctl";
    mainProgram = "dutctl";
    license = lib.licenses.bsd2;

    source = {
      git = "github:BlindspotSoftware/dutctl/710bbcd16264e62af932698a229f9be2f83f6286";
      hash = "sha256-SJfnUUo5vmmwa8qFLY4KaVyjyVnlEcVqLU1Yo3PjWug=";
    };

    build.goPackageBuilder = {
      enable = true;
      vendorHash = "sha256-vOBz9gi/cnUJ04ns1ZOgfNqzbVBE3Fd3oOfV04VSmFQ=";
      ldflags = [ "-s" ];
    };

    test.script = ''
      cfg="${pkgs.dutctl.src}/contrib/dutagent-cfg-example.yaml"

      # start agent
      dutagent -a localhost:1024 -c "$cfg" &
      agent_pid=$!
      trap 'kill "$agent_pid" 2>/dev/null || true' EXIT

      # wait for agent to become ready
      for i in $(seq 1 10); do
        dutctl list 2>/dev/null | grep -q device1 && break
        [ "$i" -eq 10 ] && { echo "FAIL: agent timed out"; exit 1; }
        sleep 1
      done
      echo "PASS: agent ready"

      # verify device status
      dutctl device1 status > status.out
      grep -q "Hello from dummy status module" status.out
      echo "PASS: device1 status"
    '';
  };
}
