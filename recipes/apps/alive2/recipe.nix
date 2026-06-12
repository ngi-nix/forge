{
  pkgs,
  ...
}:

{
  apps.alive2 = {
    displayName = "Alive2";
    description = "Automatic verification of LLVM optimizations.";
    usage = ''
      Alive2 is a translation validation tool for LLVM that verifies that compiler
      optimizations preserve the semantics of the original program.

      Run alive-tv to verify an LLVM IR transformation

      ```bash
      alive-tv src.ll tgt.ll
      ```
    '';

    links = {
      source = "https://github.com/AliveToolkit/alive2";
      website = "https://alive2.llvm.org/ce/";
    };

    ngi.grants = {
      Core = [
        "Alive2"
      ];
    };

    programs = {
      packages = [
        pkgs.alive2
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      cat <<EOF > src.ll
      define i32 @f(i32 %x) {
        ret i32 %x
      }
      EOF
      cp src.ll tgt.ll
      alive-tv src.ll tgt.ll
    '';
  };
}
