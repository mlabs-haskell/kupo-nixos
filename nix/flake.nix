ciSystems: outputs: { inputs, ... }: {
  # NixOS module for kupo service
  nixosModules.kupo = { config, lib, pkgs, ... }:
    let
      cfg = config.services.kupo;
    in
    with lib; {
      options.services.kupo = with types; {
        enable = mkEnableOption "Kupo - fast, lightweight and configurable chain-index";

        package = mkOption {
          description = "Kupo package.";
          type = package;
          default = outputs.packages.x86_64-linux.kupo;
        };

        user = mkOption {
          description = "User to run kupo service as.";
          type = str;
          default = "kupo";
        };

        group = mkOption {
          description = "Group to run kupo service as.";
          type = str;
          default = "kupo";
        };

        workDir = mkOption {
          description = ''
            Directory to start the kupo and store its data, must be under /var/lib
          '';
          type = path;
          default = "/var/lib/kupo";
        };

        nodeSocket = mkOption {
          description = "Path to cardano-node IPC socket.";
          type = path;
        };

        nodeConfig = mkOption {
          description = "Path to cardano-node config.json file.";
          type = path;
        };

        host = mkOption {
          description = "Host address or name to listen on.";
          type = str;
          default = "localhost";
        };

        port = mkOption {
          description = "TCP port to listen on.";
          type = port;
          default = 1442;
        };

        matches = mkOption {
          description = "The list of addresses to watching.";
          type = listOf str;
          default = [ "*/*" ];
        };

        since = mkOption {
          description = "Watching depth.";
          type = str;
          default = "origin";
        };

        extraArgs = mkOption {
          description = "Extra arguments to kupo command.";
          type = listOf str;
          default = [ ];
        };
      };

      config = mkIf cfg.enable (
        let
          workDirBase = "/var/lib/";
        in
        {
          assertions = mkIf (config ? services.cardano-node && config.services.cardano-node.enable) [
            #        {
            #          assertion = config.services.cardano-node.systemdSocketActivation;
            #          message = "The option services.cardano-node.systemdSocketActivation needs to be enabled to use Kupo with the cardano-node configured by that module.";
            #        }
            {
              assertion = lib.hasPrefix workDirBase cfg.workDir;
              message = "The option services.kupo.workDir should have ${workDirBase} as a prefix!";
            }
          ];

          services.kupo = {
            #        workDir = mkDefault "/var/lib/kupo";
          }
          # get configuration from cardano-node module if there is one
          // mkIf (config ? services.cardano-node && config.services.cardano-node.enable) {
            nodeSocket = mkDefault config.services.cardano-node.socketPath;
            # hacky way to get cardano-node config path from service
            #          nodeConfig = mkDefault (builtins.head (
            #            builtins.match ''.* (/nix/store/[a-zA-Z0-9]+-config-0-0\.json) .*''
            #              (builtins.readFile (builtins.replaceStrings [ " " ] [ "" ] config.systemd.services.cardano-node.serviceConfig.ExecStart))
            #          ));
          };

          users.users.kupo = mkIf (cfg.user == "kupo") {
            isSystemUser = true;
            group = cfg.group;
            extraGroups = [ "cardano-node" ];
          };
          users.groups.kupo = mkIf (cfg.group == "kupo") { };

          systemd.services.kupo = {
            enable = true;
            after = [ "cardano-node.service" ];
            wantedBy = [ "multi-user.target" ];

            script = escapeShellArgs (concatLists [
              [ "${cfg.package}/bin/kupo" ]
              [ "--node-socket" cfg.nodeSocket ]
              [ "--node-config" cfg.nodeConfig ]
              [ "--host" cfg.host ]
              [ "--port" cfg.port ]
              [ "--workdir" cfg.workDir ]
              (concatLists (map (m: [ "--match" m ]) cfg.matches))
              [ "--since" cfg.since ]
              cfg.extraArgs
            ]);

            serviceConfig = {
              AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
              CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
              DevicePolicy = "closed";
              Group = cfg.group;
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              NoNewPrivileges = true;
              PrivateDevices = true;
              PrivateMounts = true;
              PrivateTmp = true;
              PrivateUsers = true;
              ProcSubset = "pid";
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              ProtectSystem = "strict";
              RemoveIPC = true;
              RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              StateDirectory = lib.removePrefix workDirBase cfg.workDir;
              SystemCallArchitectures = "native";
              SystemCallFilter = [ "~@cpu-emulation @debug @keyring @mount @obsolete @privileged @setuid @resources" ];
              UMask = "0077";
              User = cfg.user;
              WorkingDirectory = cfg.workDir;
            };
          };
        }
      );
    };
  herculesCI = {
    inherit ciSystems;
  };
}
