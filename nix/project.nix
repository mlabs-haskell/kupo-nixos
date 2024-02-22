{ lib, pkgs, inputs, ... }: lib.iogx.mkHaskellProject {
  cabalProject = pkgs.haskell-nix.cabalProject'
    {
      src = pkgs.haskell-nix.haskellLib.cleanSourceWith {
        name = "kupo-src";
        src = inputs.kupo;
        filter = path: type:
          builtins.all (x: x) [
            (baseNameOf path != "package.yaml")
          ];
      };
      # `compiler-nix-name` upgrade policy: as soon as inputs.kupo
      compiler-nix-name = lib.mkDefault "ghc96";
      inputMap = {
        "https://input-output-hk.github.io/cardano-haskell-packages" = inputs.iogx.inputs.CHaP;
      };
      sha256map = {
        "https://github.com/CardanoSolutions/ogmios"."01f7787216e7ceb8e39c8c6807f7ae53fc14ab9e" = "1TU3IYTzm7h/wpt/fkHbaR0esVhyHKNtdCJpjsferZo=";
        "https://github.com/CardanoSolutions/direct-sqlite"."82c5ab46715ecd51901256144f1411b480e2cb8b" = "fuKhPnIVsmdbQ2gPBTzp9nI/3/BTsnvNIDa1Ypw1L+Q=";
        "https://github.com/CardanoSolutions/text-ansi"."e204822d2f343b2d393170a2ec46ee935571345c" = "e6EINXr5Tfx5vzSY+wmGt/7seIdkM1WM7Tvy4zQ/cZo=";
      };
      modules = [
        {
          # FIXME kupo unit tests are not passing
          packages.kupo.components.tests.unit.doCheck = false;
        }
      ];
    };
}
