{
  description = "Nix flake for Kupo including a NixOS module";
  inputs = {
    CHaP = {
      url = "github:input-output-hk/cardano-haskell-packages?ref=repo";
      flake = false;
    };
    iogx = {
      url = "github:input-output-hk/iogx";
      inputs.CHaP.follows = "CHaP";
    };
    kupo = {
      url = "github:CardanoSolutions/kupo/v2.9.0";
      flake = false;
    };
  };
  outputs = inputs@{ self, ... }:
    let
      # TODO enable kupo supported OS's
      systems = [ "x86_64-linux" ];
      ciSystems = systems;
    in
    inputs.iogx.lib.mkFlake {
      inherit inputs systems;
      repoRoot = ./.;
      outputs = import ./nix/outputs.nix;
      flake = (import ./nix/flake.nix) ciSystems self;
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
