{
  pkgs,
  config,
  ...
}:
let
  recipe = config.pkgs.self-ref;
in
{
  pkgs.self-ref = {
    version = "1.2.3";
    description = "Recipe whose git revision references its own version.";
    mainProgram = "self-ref";

    source = {
      git = "github:example/self-ref/v${recipe.version}";
      hash = "sha256-KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK=";
    };

    build.builders.standard = {
      enable = true;
    };

    test.script = ''
      self-ref --version | grep -q ${recipe.version}
    '';
  };
}
