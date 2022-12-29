{
  description = "NixOS module for Kupo";
  nixConfig = {
    extra-experimental-features = [ "nix-command" "flakes" ];
    allow-import-from-derivation = "true";
    cores = "1";
    max-jobs = "auto";
    auto-optimise-store = "true";
  };
  inputs = {
    # should follow inputs in https://github.com/CardanoSolutions/kupo/blob/master/default.nix#L22
    haskell-nix.url = github:input-output-hk/haskell.nix/974a61451bb1d41b32090eb51efd7ada026d16d9;
    iohk-nix.url = github:input-output-hk/iohk-nix/edb2d2df2ebe42bbdf03a0711115cf6213c9d366;

    nixpkgs.follows = "haskell-nix/nixpkgs";
    iohk-nix.inputs.nixpkgs.follows = "haskell-nix/nixpkgs";
    kupo = {
      url = github:CardanoSolutions/kupo;
      flake = false;
    };
  };
  outputs = inputs@{ self, nixpkgs, haskell-nix, ... }:
    let
      perSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      pkgs = perSystem (system: import nixpkgs { inherit system; overlays = [ haskell-nix.overlay ]; inherit (haskell-nix) config; });
      project = perSystem (system: pkgs.${system}.haskell-nix.project {
        compiler-nix-name = "ghc8107";
        projectFileName = "cabal.project";
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
        services.kupo.package = lib.mkModuleDefault self.packages.${pkgs.system}.kupo;
      };
    };
}
