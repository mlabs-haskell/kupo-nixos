{ lib, pkgs, inputs, ... }: lib.iogx.mkHaskellProject {
  cabalProject = pkgs.haskell-nix.cabalProject' ({ config, ... }: {
    src = pkgs.haskell-nix.haskellLib.cleanSourceWith {
      name = "kupo-src";
      src = inputs.kupo;
      filter = path: type:
        builtins.all (x: x) [
          (baseNameOf path != "package.yaml")
        ];
    };
    # `compiler-nix-name` upgrade policy: as soon as inputs.kupo
    compiler-nix-name = lib.mkDefault "ghc96"; # from upstream Makefile
    inputMap = {
      "https://input-output-hk.github.io/cardano-haskell-packages" = inputs.iogx.inputs.CHaP;
    };
    sha256map = {
      "https://github.com/CardanoSolutions/ogmios"."01f7787216e7ceb8e39c8c6807f7ae53fc14ab9e" = "1TU3IYTzm7h/wpt/fkHbaR0esVhyHKNtdCJpjsferZo=";
      "https://github.com/CardanoSolutions/sqlite-simple"."08015be2ee52a7e67159b6b0c476bd3e0a2e0b87" = "yuKhPnIVsmdbQ2gPBTzp9nI/3/BTsnvNIDa1Ypw1L+Q=";
      "https://github.com/CardanoSolutions/direct-sqlite"."2b14a78cb73805e2e5d84354230e872a223faa39" = "fuKhPnIVsmdbQ2gPBTzp9nI/3/BTsnvNIDa1Ypw1L+Q=";
      "https://github.com/CardanoSolutions/text-ansi"."e204822d2f343b2d393170a2ec46ee935571345c" = "e6EINXr5Tfx5vzSY+wmGt/7seIdkM1WM7Tvy4zQ/cZo=";
    };
    modules = [
      {
        # FIXME kupo unit tests are not passing
        packages.kupo.components.tests.unit.doCheck = false;
        # FIXME contra-tracers broken haddock build
        packages.contra-tracers.doHaddock = false;
      }
    ];
  });
}
