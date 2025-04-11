{
  description = "A garnix module for Uptime Kuma";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.garnix-lib.url =
    "github:jfroche/garnix-lib/jfroche/expose-module-for-system";

  outputs = { self, nixpkgs, garnix-lib, }:
    let
      lib = nixpkgs.lib;
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      uptimeKumaSubmodule.options = {
        port = lib.mkOption {
          type = lib.types.port;
          description = "The port in which to run uptime-kuma";
          default = 3001;
        };
      };
    in {
      garnixModules.default = { pkgs, config, ... }: {
        options = {
          uptimeKuma = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule uptimeKumaSubmodule);
            description = "An attrset of uptime-kuma instances";
          };
        };

        config = {
          nixosConfigurations.default = builtins.attrValues (builtins.mapAttrs
            (name: projectConfig: {
              services.uptime-kuma = {
                enable = true;
                settings.UPTIME_KUMA_PORT = toString projectConfig.port;
              };
              garnix.server.persistence = {
                enable = true;
                name = "uptimeKuma";
              };
              services.nginx = {
                enable = true;
                recommendedProxySettings = true;
                recommendedOptimisation = true;
                virtualHosts.default = {
                  locations."/".proxyPass =
                    "http://localhost:${toString projectConfig.port}";
                };
              };
              networking.firewall.allowedTCPPorts = [ 80 ];
            }) config.uptimeKuma);
        };
      };
      checks = import ./tests.nix { inherit self pkgs garnix-lib; };
    };
}
