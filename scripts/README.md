### Setup

- Log in to Netlify using an account that will act as the owner/admin for the organization's Netlify team.
- In the Netlify dashboard, click Add new site > Import an existing project > Github.
- A GitHub authorization window will pop up. If you are asked which account/organization to install the app on, select the ngi-nix organization.
- IMPORTANT: On the permission screen, scroll down to the Repository access section.
  Change the selection from "All repositories" to "Only select repositories".
  Only select single repo, for us `ngi-nix/forge`.
- Install.

- After authorization, Netlify will redirect you back to its dashboard to pick the repository.
  - Select `ngi-nix/forge`.
- You will be taken to the "Site settings and deploy" screen.
- Important: Leave the build commands and publish directories blank or at their defaults. The repository contains a netlify.toml file that Netlify will automatically read to configure the Nix build environment.

- At the end, remove the annoying bottom collaboration banner https://app.netlify.com/projects/ngi-forge/configuration/deploys#collaboration-tools

### Known issues

- problem: nix cannot be installed on netlify's container

With new rust installer

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install linux --no-confirm --enable-flakes --init none
```

```log
10:45:49 AM: Installing Nix...
10:45:50 AM: info: downloading installer
10:45:50 AM:  INFO nix-installer v2.34.5
10:45:50 AM: `nix-installer` needs to run as `root`, attempting to escalate now via `sudo`...
10:45:50 AM: Error:
10:45:50 AM:    0: Executing `nix-installer` as `root` via `sudo`
10:45:50 AM:    1: ENOENT: No such file or directory
```

With old nix installer

```
10:49:06 AM: /tmp/nix-binary-tarball-unpack.vtEbNdLfOs/unpack/nix-2.34.5-x86_64-linux/install: 149: sudo: not found
```

- Resources
  - https://discourse.nixos.org/t/use-nix-in-netlify/17695/15
  - https://github.com/jakejarvis/netlify-plugin-cache/issues/27
  - https://github.com/justinas/nix-netlify-poc/blob/master/build.sh
  - https://github.com/netlify/build-image/issues/617
  - https://github.com/netlify/build-image#archive-note
- solution: nix-portable https://github.com/DavHau/nix-portable/releases

- problem: result symlink can't be read from the container, only valid inside
  nix-portable's sandbox
- solution: copy to outside resolving symlinks from inside the sandbox
  - found from
    [this post by Joachim Breitner](https://discourse.nixos.org/t/use-nix-in-netlify/17695/15)

- problem: even that copy command from within nix-portable sandbox fails with
  `error: setting up a private mount namespace: Operation not permitted`
- solution: Several issues on nix-portable say to use `bwrap` runtime for now
  - https://github.com/search?q=repo%3ADavHau%2Fnix-portable+setting+up+a+private+mount+namespace&type=issues
  - https://github.com/DavHau/nix-portable/issues/138#issuecomment-3053848913
  - https://github.com/DavHau/nix-portable/issues/103#issuecomment-2071741579
  - https://github.com/DavHau/nix-portable/issues/98#issuecomment-2106376504
  - https://github.com/DavHau/nix-portable/issues/66#issuecomment-2067802826
