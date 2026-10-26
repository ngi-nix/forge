{
  config,
  pkgs,
  ...
}:

let
  app = config.apps.scion;
in
{
  pkgs.scion = {
    build.identityBuilder = {
      enable = true;
      # Ship local topology tools adapted to run inside Nix shell environment
      derivation = pkgs.pkgsOriginal.scion.overrideAttrs (previousAttrs: {
        # Required by patchShebangs
        buildInputs = previousAttrs.buildInputs or [ ] ++ [ pkgs.bash ];

        postInstall = previousAttrs.postInstall + ''
          mkdir --parents $out/share/scion/tools $out/share/scion/topology
          cp topology/tiny4.topo $out/share/scion/topology/
          cp --recursive \
            tools/docker-ip \
            tools/supervisor.sh \
            tools/supervisord.conf \
            tools/topogen.py \
            tools/topology \
            $out/share/scion/tools/

          pushd $out/share/scion/tools

          substituteInPlace topology/common.py \
            --replace-fail "'tools/docker-ip'" "'$out/share/scion/tools/docker-ip'"

          substituteInPlace topology/supervisor.py \
            --replace-fail '"bin/daemon"' '"scion-daemon"' \
            --replace-fail '"bin/dispatcher"' '"scion-dispatcher"' \
            --replace-fail '"bin/control"' '"scion-control"' \
            --replace-fail '"bin/router"' '"scion-router"'

          patchShebangs --host docker-ip supervisor.sh

          substituteInPlace supervisor.sh \
            --replace-fail bin/supervisorctl supervisorctl \
            --replace-fail bin/supervisord supervisord

          # Disable wildcards plugin (currently unavailable on Nixpkgs)
          substituteInPlace supervisord.conf \
            --replace-fail '[ctlplugin:wildcards]' ';[ctlplugin:wildcards]' \
            --replace-fail 'supervisor.ctl_factory = supervisorwildcards' ';supervisor.ctl_factory = supervisorwildcards' \
            --replace-fail 'match_group = 1' ';match_group = 1'
          popd
        '';
      });
    };
  };

  apps.scion = {
    displayName = "SCION";
    description = "SCION: a next-generation inter-domain routing architecture.";
    usage = ''
      > [!CAUTION]
      > This is a complex project, and the example below is only for testing purposes.

      From the
      [upstream documentation](https://docs.scion.org/en/v0.15.1/dev/run.html#running-scion-locally):

      > _SCION is an Internet architecture and SCION networks are composed of
      > many hosts running the SCION control-plane services, routers, and
      > SCION-enabled applications.
      > To simplify development, testing, and tinkering, we provide a tool that
      > generates test topologies and runs an entire SCION “Internet” on a single
      > machine.
      > Packets are only sent between different processes on the same host, not
      > over the network._

      > _Running SCION in this development setup, is also called running a
      > **local topology**._

      A sample
      [local topology environment](https://docs.scion.org/en/v0.15.1/dev/run.html#local-topology-environment)
      is thus provided
      (`tiny4`, with the default
      [`supervisor`](https://docs.scion.org/en/v0.15.1/dev/run.html#supervisor-section)
      backend orchestrator),
      based on the
      [Quickstart](https://docs.scion.org/en/v0.15.1/dev/run.html#quickstart)
      instructions provided in the SCION docs.

      #### Running SCION locally

      0. [First, launch the shell environment](app/${app.name}#run-shell)
      containing `${app.name}` and create an empty working directory

      ```bash
      mkdir scion && cd scion
      ```

      1. Initialize local topology

      ```bash
      scion-topology-tiny4-init # prepare all required files in the current directory
      ```

      2. Launch all required services

      ```bash
      tools/supervisor.sh start all
      ```

      you should see this output:

      ```
      dispatcher: started
      as1-ff00_0_110:br1-ff00_0_110-1: started
      as1-ff00_0_110:br1-ff00_0_110-2: started
      as1-ff00_0_110:cs1-ff00_0_110-1: started
      as1-ff00_0_110:sd1-ff00_0_110: started
      as1-ff00_0_111:br1-ff00_0_111-1: started
      as1-ff00_0_111:cs1-ff00_0_111-1: started
      as1-ff00_0_111:sd1-ff00_0_111: started
      as1-ff00_0_112:br1-ff00_0_112-1: started
      as1-ff00_0_112:cs1-ff00_0_112-1: started
      as1-ff00_0_112:sd1-ff00_0_112: started
      ```

      3. Check connectivity

      ```bash
      scion showpaths --sciond 127.0.0.19:30255 1-ff00:0:110
      scion ping --sciond 127.0.0.19:30255 1-ff00:0:110,127.0.0.1 # interrupt by pressing Control-C
      ```

      you should see something like this, which shows traffic flowing between
      the simulated autonomous systems (AS), proving that the topology has been
      successfully deployed locally:

      ```
      $ scion showpaths --sciond 127.0.0.19:30255 1-ff00:0:110
      Available paths to 1-ff00:0:110
      2 Hops:
      [0] Hops: [1-ff00:0:111 41>1 1-ff00:0:110] MTU: 1280 NextHop: 127.0.0.17:31008 Status: alive LocalIP: 127.0.0.1
      $ scion ping --sciond 127.0.0.19:30255 1-ff00:0:110,127.0.0.1
      Resolved local address:
      127.0.0.1
      Using path:
      Hops: [1-ff00:0:111 41>1 1-ff00:0:110] MTU: 1280 NextHop: 127.0.0.17:31008

      PING 1-ff00:0:110,127.0.0.1 pld=0B scion_pkt=80B
      88 bytes from 1-ff00:0:110,127.0.0.1: scmp_seq=0 time=0.635ms
      88 bytes from 1-ff00:0:110,127.0.0.1: scmp_seq=1 time=0.879ms
      88 bytes from 1-ff00:0:110,127.0.0.1: scmp_seq=2 time=0.907ms
      88 bytes from 1-ff00:0:110,127.0.0.1: scmp_seq=3 time=0.880ms
      88 bytes from 1-ff00:0:110,127.0.0.1: scmp_seq=4 time=0.867ms
      88 bytes from 1-ff00:0:110,127.0.0.1: scmp_seq=5 time=0.848ms
      88 bytes from 1-ff00:0:110,127.0.0.1: scmp_seq=6 time=1.123ms
      88 bytes from 1-ff00:0:110,127.0.0.1: scmp_seq=7 time=1.031ms
      88 bytes from 1-ff00:0:110,127.0.0.1: scmp_seq=8 time=1.090ms
      ^C
      --- 1-ff00:0:110,127.0.0.1 statistics ---
      9 packets transmitted, 9 received, 0% packet loss, time 8314.129ms
      rtt min/avg/max/mdev = 0.635/0.918/1.123/0.139 ms
      ```

      4. Stop all running SCION services

      ```bash
      tools/supervisor.sh stop all
      ```

      5. Stop `supervisor` daemon, removing `/tmp/supervisor.sock` upon shutdown

      ```bash
      tools/supervisor.sh shutdown
      ```

      #### Additional resources

      ##### Presentation by the original creator

      - <https://youtu.be/pT23lMsBOf8>

      ##### References

      - <https://en.wikipedia.org/wiki/SCION_(Internet_architecture)>

      ##### Open-Source implementation (this one)

      - <https://github.com/scionproto/scion/wiki>

      ##### Build from sources (development mode)

      - <https://github.com/scionproto/scion#build-from-sources>

      ##### Demo Apps

      - <https://docs.scionlab.org/content/apps/bittorrent.html>
      - <https://github.com/netsys-lab/bittorrent-over-scion#usage>
      - <https://github.com/lschulz/ioq3-scion>

      ##### SCION PAN Bindings for C, C++ and Python

      - <https://github.com/lschulz/pan-bindings>

      ##### NixOS resources

      - <https://search.nixos.org/packages?channel=unstable&query=SCION>
      - <https://search.nixos.org/options?channel=unstable&query=SCION>

      - <https://wiki.nixos.org/wiki/SCION> - Outdated as of 2026-08-26 wrt.
      registration to SCIONLab, which is now unavailable, but illustrative
      still. See the note on <https://www.scionlab.org>.

    '';

    icon = ./icon.svg;

    links = {
      website = "https://www.scion.org";
      docs = "https://docs.scion.org";
      source = "https://github.com/scionproto/scion";
    };

    ngi.grants = {
      Commons = [
        "SCION-IP-gateway"
        "SelectCast"
      ];
      Core = [
        "SCION-1M"
        "Verified-SCION-router"
        "SCION-router-codealignment"
        "SCION-IPFS"
      ];
      Entrust = [
        "SCION-proxy"
      ];
      Review = [
        "SCION-Rains"
        "SCION-Swarm"
        "SCION-geo"
        "TrustING"
      ];
    };

    programs = {
      packages = [
        pkgs.scion
        pkgs.python3Packages.supervisor

        (pkgs.writeShellApplication {
          name = "scion-topology-tiny4-init";
          runtimeInputs = [
            pkgs.busybox

            (pkgs.python3.withPackages (ps: [
              ps.plumbum
              ps.pyyaml
              ps.toml
            ]))
          ];
          text = ''
            scion_share="${pkgs.scion}/share/scion"

            export DOCKER_IF=lo              # to appease tools/docker-ip when docker is not available
            export PYTHONDONTWRITEBYTECODE=1 # don't try to write .pyc files
            export PYTHONPATH="$scion_share/tools"

            echo " * Ensure availability of the 'gen-cache' directory, required by SQLite"
            mkdir --verbose --parents gen-cache

            echo " * Install topology/tiny4.topo"
            install --mode 644 --target-directory topology -D "$scion_share/topology/tiny4.topo"

            echo ' * Generate topology'
            python3 "$scion_share/tools/topogen.py" -c topology/tiny4.topo

            echo ' * Install tools/supervisord.conf and tools/supervisor.sh'
            install --mode 644 --target-directory tools -D "$scion_share/tools/supervisord.conf"
            install --mode 755 --target-directory tools -D "$scion_share/tools/supervisor.sh"
          '';
        })
      ];

      runtimes.shell.enable = true;
      runtimes.browser.enable = true;
    };

    test.programs.script = ''
      scion help | grep SCION
    '';
  };
}
