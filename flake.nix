{
  description = "NixOS module for Kupo";
  nixConfig = {
    extra-experimental-features = [ "nix-command" "flakes" "ca-derivations"];
    allow-import-from-derivation = "true";
    cores = "1";
    max-jobs = "auto";
    auto-optimise-store = "true";
  };
  inputs = {
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    iohk-nix.url = "github:input-output-hk/iohk-nix";
    kupo = {
      url = "github:CardanoSolutions/kupo";
      flake = false;
    };
  };
  outputs = inputs@{self, ...}:
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
      flake = ((import inputs.kupo)
        {
          inherit system;
          haskellNix = import haskellNixSrc { };
          iohkNix = import iohkNixSrc { };
        }).flake {};
    in {
      packages.${system}.kupo = flake.packages."kupo:exe:kupo";

      nixosModules.kupo = { pkgs, lib, ... }: {
        imports = [ ./kupo-nixos-module.nix ];
        services.kupo.package = lib.mkDefault self.flake.${pkgs.system}.packages."kupo:exe:kupo";
      };
    };
}
