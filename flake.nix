{
  description = "Nix flake for Kupo including a NixOS module";
  inputs = {
    iogx.url = "github:input-output-hk/iogx";
    kupo = {
      url = "github:Fourierlabs/kupo";
      flake = false;
    };
  };
  outputs = inputs@{ self, ... }:
    let
      # TODO enable kupo supported OS's
      systems = [ "x86_64-linux" ];
      ciSystems = systems;
      hs-kupo = { lib, pkgs, inputs, ... }: lib.iogx.mkHaskellProject {
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
      };
      nixos-kupo = { pkgs, lib, ... }: {
        flake.nixosModules.kupo = {
          imports = [ ./kupo-nixos-module.nix ];
          services.kupo.package = lib.mkOptionDefault pkgs.kupo;
        };
      };
    in
    inputs.iogx.lib.mkFlake {
      inherit inputs systems;
      outputs = c@{ system, ... }: [
        (hs-kupo c)
        (nixos-kupo c)
        {
          packages.default = self.packages.${system}.kupo;
        }
      ];
      flake.herculesCI = {
        inherit ciSystems;
      };
    };

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
    allow-import-from-derivation = true;
  };
}
