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
      nixos = import ./nixos.nix inputs self;
    in
    inputs.iogx.lib.mkFlake {
      inherit inputs systems;
      repoRoot = ./.;
      outputs = import ./nix/outputs.nix;
      flake = {
        inherit (nixos) nixosModules;
        herculesCI = {
          inherit ciSystems;
        };
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
