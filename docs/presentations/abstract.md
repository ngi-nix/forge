# NGI Forge — Software Distribution Platform for NGI projects

The Next Generation Internet (NGI) program of the European Commission, through
NLnet, provides funding for more than 1000 free software projects. The NixOS
Foundation NGI team is an NGI consortium partner for software packaging, with
a mission to ensure that all funded software is packaged, deployable, and
contributes to the long-term sustainability of the upstream software development
ecosystem. We use Nix and NixOS to achieve this.

The challenge we face is how to scale packaging and long-term package
maintenance. Ideally, upstream software authors would be able to package their
own software, maintain packages, and set up development environments themselves — but
Nix is known for a steep learning curve, which is not an appealing proposition
for everyone. Can we build a platform that is intuitive enough to appeal to a
general software developer audience with no prior Nix experience, while still
exposing all the powerful features of Nix and NixOS?

This talk introduces NGI Forge, a platform that lowers the barrier to packaging
and deploying NGI-funded software with Nix. We will explore its design, how it
guides contributors through the packaging process, and how it feeds back into
Nixpkgs and the wider Nix community.

NGI Forge URL: https://ngi.nixos.org/
