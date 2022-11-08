# NixOS module for Kupo

A flake and a NixOS module for [Kupo](https://github.com/CardanoSolutions/kupo/), since Kupo doesn't provide ones out-of-the-box.

A sample usage example:

```
{ config, lib, pkgs, inputs, ... }@args: {
  imports = with inputs; [
    kupo-nixos.nixosModules.kupo
  ];
  config =
    {
      networking.firewall.allowedTCPPorts = [ 22 1442 ];

      # kupo
      services.kupo = with cardano-config; {
        enable = true;
        # this user should have access to cardano-node IPC socket
        user = "kupo";
        group = "kupo";
        # The next two lines just illustrates how this may be implemented
        nodeConfig = "${cardano-config}/${network}/config.json";
        nodeSocket = config.services.cardano-node.socketPath;
        host = "0.0.0.0";
        matches = [
          # scripts
          "ea2e57ace99da3c9c3dd233d6fffb84983061bdbf6774e37e0de3d51/*"
          # assets
          "add8604a36a46446dd22281473614c5b390afbc064ff1338516b19f5.*"
        ];
        # You may set this value, but bear in mind that if cardano-node hasn't synced up to
        # specified point, Kupo will fail saying "there is no intersection"
        # since = "2906230.494772d6e3fecf0a9bd3fab9a8787dc38c25c650fa58474d13e49d59407ba934";
      };
    };
}

```
