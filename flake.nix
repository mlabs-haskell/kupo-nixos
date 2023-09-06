{
  description = "Nix flake for Kupo including a NixOS module";
  inputs = {
    # should always follow inputs in https://github.com/CardanoSolutions/kupo/blob/master/default.nix
    haskell-nix.url = "github:input-output-hk/haskell.nix/1b4bccb032d5a32fee0f5b7872660c017a0748d";
    iohk-nix.url = "github:input-output-hk/iohk-nix/4b342603a36edacc9610139db8d1b6f77cd272c7";
    cardanoPkgs = {
      url = "github:input-output-hk/cardano-haskell-packages/4278da8003518bcd3707c079639a55b58b77294";
      flake = false;
    };
    nixpkgs.follows = "haskell-nix/nixpkgs-unstable";
    kupo = {
      url = "github:mlabs-haskell/kupo/aciceri/fix-nix-build";
      flake = false;
    };
  };
  outputs = inputs@{ self, nixpkgs, haskell-nix, iohk-nix, cardanoPkgs, ... }:
    let
      perSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      # FIXME should use pkgs.pkgsCross.musl64 to be 100% coherent with upstream
      pkgs = perSystem (system: (import nixpkgs { inherit system; overlays = [haskell-nix.overlay iohk-nix.overlays.crypto iohk-nix.overlays.haskell-nix-crypto]; inherit (haskell-nix) config; }));
      project = perSystem (system: pkgs.${system}.haskell-nix.project {
        compiler-nix-name = "ghc8107";
        projectFileName = "cabal.project";
        inputMap = { "https://input-output-hk.github.io/cardano-haskell-packages" = cardanoPkgs; };
        sha256map = {
          "https://github.com/CardanoSolutions/direct-sqlite.git"."82c5ab46715ecd51901256144f1411b480e2cb8b" = "fuKhPnIVsmdbQ2gPBTzp9nI/3/BTsnvNIDa1Ypw1L+Q=";
          "https://github.com/CardanoSolutions/text-ansi.git"."dd81fe6b30e78e95589b29fd1b7be1c18bd6e700" = "mCFkVltVeOpDfEkQwClEXFAiOV8lSejmrFBRQhmeLDE=";
        };
        src = nixpkgs.lib.cleanSourceWith {
          name = "kupo-src";
          src = inputs.kupo;
          filter = path: type:
            builtins.all (x: x) [
              (baseNameOf path != "package.yaml")
            ];
        };
      });
      flake = perSystem (system: project.${system}.flake { });
    in
    {
      packages = perSystem (system: {
        kupo = flake.${system}.packages."kupo:exe:kupo";
        default = self.packages.${system}.kupo;
      });
      nixosModules.kupo = { pkgs, lib, ... }: {
        imports = [ ./kupo-nixos-module.nix ];
        services.kupo-261.package = lib.mkOptionDefault self.packages.${pkgs.system}.kupo;
      };
      herculesCI.ciSystems = [ "x86_64-linux" ];
    };
}
