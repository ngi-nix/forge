# NGI Forge maintainer list.
# Add yourself here if you are not yet in the Nixpkgs maintainer list.
# Format matches lib.maintainers in Nixpkgs, an example is provided below.
# Usage in recipes: { lib, ... }: { maintainers = [ lib.maintainers.<handle> ]; }
{
  provider-team = {
    name = "NGI Team";
    github = "ngi-nix";
    email = "ngi@nixos.org";
  };

  # example-maintainer = {
  #   name = "Example Maintainer";
  #   github = "example";
  #   email = "example@example.com";
  # };
}
