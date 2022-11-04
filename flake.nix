{
  description = "NixOS module for Kupo";
  nixConfig = {
    extra-experimental-features = [ "nix-command" "flakes"];
    allow-import-from-derivation = "true";
    cores = "1";
    max-jobs = "auto";
    auto-optimise-store = "true";
  };
  inputs = {
    haskell-nix.url = "github:input-output-hk/haskell.nix/974a61451bb1d41b32090eb51efd7ada026d16d9";
    iohk-nix.url = "github:input-output-hk/iohk-nix/edb2d2df2ebe42bbdf03a0711115cf6213c9d366";
    nixpkgs.follows = "haskell-nix/nixpkgs";
    iohk-nix.inputs.nixpkgs.follows ="haskell-nix/nixpkgs";
    kupo = {
      url = "github:CardanoSolutions/kupo";
      flake = false;
    };
  };
  outputs = inputs@{self, nixpkgs, ...}:
    let
      pins = (__fromJSON (__readFile ./flake.lock)).nodes;
      haskellNixPin = pins.haskell-nix.locked;
      iohkNixPin = pins.iohk-nix.locked;
      haskellNixSrc = builtins.fetchTarball {
        url = "https://github.com/input-output-hk/haskell.nix/archive/${haskellNixPin.rev}.tar.gz";
        sha256 = haskellNixPin.narHash;
      };
      iohkNixSrc = builtins.fetchTarball {
        url = "https://github.com/input-output-hk/iohk-nix/archive/${iohkNixPin.rev}.tar.gz";
        sha256 = iohkNixPin.narHash;
      };
      system = "x86_64-linux";
      # we need it because of the way haskell.nix loads pkgs
      pkgs = import nixpkgs { localSystem = { inherit system; }; };
      flake = ((import inputs.kupo)
        {
          inherit system;
          haskellNix = import haskellNixSrc { inherit pkgs; };
          iohkNix = import iohkNixSrc { inherit system; };
          nixpkgsArgs = { inherit system; };
        }).flake {};
    in {
      packages.${system}.kupo = flake.packages."kupo:exe:kupo";

      nixosModules.kupo = { pkgs, lib, ... }: {
        imports = [ ./kupo-nixos-module.nix ];
        services.kupo.package = lib.mkDefault self.flake.${pkgs.system}.packages."kupo:exe:kupo";
      };
    };
}