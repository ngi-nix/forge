{
  pkgs,
  ...
}:

{
  pkgs.scion = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.scion;
    };
  };

  apps.scion = {
    displayName = "SCION";
    description = "SCION: a next-generation inter-domain routing architecture.";
    usage = ''
       A sample local topology environment is provided, based on the
       [Quickstart](https://docs.scion.org/en/latest/dev/run.html#quickstart)
       instructions provided in the SCION docs.

       0. Create an empty directory to work in, and enter it

       ```bash
       mkdir scion && cd scion
       ```

       1. Initialize local topology

       ```bash
       scion-tiny4-init # prepare all required files in the current directory
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

       or you can run `tools/supervisor.sh` interactively:

       ```bash
       tools/supervisor.sh
       ```

       and issue commands at the prompt, e.g.:

      `start all`, `stop all`, `tail -f <process_id>`, ...

       Note that you can autocomplete commands by pressing `<Tab>`.

       3. Check connectivity

       ```bash
       scion showpaths --sciond 127.0.0.19:30255 1-ff00:0:110
       scion ping --sciond 127.0.0.19:30255 1-ff00:0:110,127.0.0.1 # interrupt by pressing Control-C
       ```

       you should see something like this:

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

       #### Resources

       ##### Presentation by the original creator

       - <https://youtu.be/pT23lMsBOf8>

       ##### References

       - <https://en.wikipedia.org/wiki/SCION_(Internet_architecture)>

       ##### Documentation

       - <https://www.scion.org>
       - <https://apps.scion.org>

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

       ##### SCION-related packages available on Nixpkgs

       - <https://search.nixos.org/packages?channel=unstable&query=SCION>

       ##### SCION-related options available on NixOS

       - <https://search.nixos.org/options?channel=unstable&query=SCION>

       ##### SCION entry on NixOS Wiki

       Outdated as of 2026-08-26 wrt. registration to SCIONLab, which is now
       unavailable, but illustrative still.  See the note on
       <https://www.scionlab.org>.

       - <https://wiki.nixos.org/wiki/SCION>

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
            echo " * Ensure availability of the 'gen-cache' directory, required by SQLite"
            mkdir --verbose --parents gen-cache

            echo " * Install topology/tiny4.topo"
            install --mode 644 --target-directory topology -D ${pkgs.scion.src}/topology/tiny4.topo

            echo ' * Install tools/docker-ip'
            install --mode 755 --target-directory tools -D ${pkgs.scion.src}/tools/docker-ip
            sed --in-place tools/docker-ip             \
                --expression=s,^#!/bin/bash,#!/bin/sh, \

            echo ' * Generate topology files on ./gen'
            export DOCKER_IF=lo              # to appease tools/docker-ip when docker is not available
            export PYTHONDONTWRITEBYTECODE=1 # don't try to write .pyc files
            export PYTHONPATH="${pkgs.scion.src}/tools"
            python3 "${pkgs.scion.src}/tools/topogen.py" -c topology/tiny4.topo

            echo ' * Update paths to SCION components on gen/supervisord.conf'
            sed --in-place gen/supervisord.conf                 \
                --expression=s,bin/daemon,scion-daemon,         \
                --expression=s,bin/dispatcher,scion-dispatcher, \
                --expression=s,bin/control,scion-control,       \
                --expression=s,bin/router,scion-router,

            echo ' * Install tools/supervisord.conf'
            echo " * Disable unavailable plugin 'wildcards' on tools/supervisord.conf"
            awk '
                /^\[ctlplugin:wildcards\]/ {
                    print "; forge: disable wildcards plugin (currently unavailable on Nixpkgs)"
                    comment = 1
                }
                comment && /^$/ { comment = 0 }
                comment         { print ";" $0; next }
                1
            ' ${pkgs.scion.src}/tools/supervisord.conf > tools/supervisord.conf

            echo ' * Install tools/supervisor.sh'
            install --mode 755 --target-directory tools -D ${pkgs.scion.src}/tools/supervisor.sh

            echo ' * Update paths on tools/supervisord.sh'
            sed --in-place tools/supervisor.sh                  \
                --expression=s,^#!/bin/bash,#!/bin/sh,          \
                --expression=s,bin/supervisorctl,supervisorctl, \
                --expression=s,bin/supervisord,supervisord,
          '';
        })

      ];

      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      scion help | grep SCION
    '';
  };
}
