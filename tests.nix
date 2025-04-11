{ self, pkgs, garnix-lib }: {
  x86_64-linux.default = pkgs.testers.runNixOSTest ({ lib, ... }: {
    name = "uptime-kuma";
    nodes.default = { lib, pkgs, ... }:
      let
        evaledGarnixModuleConfig = (garnix-lib.lib.evaledModulesForSystems {
          modules = [ self.garnixModules.default ({ }) ];
          config = { uptimeKuma.default = { port = 8001; }; };
        }).x86_64-linux;
      in {
        imports = [ garnix-lib.nixosModules.garnix ]
          ++ evaledGarnixModuleConfig.config.nixosConfigurations.default;
        garnix.server.isVM = true;
        garnix.server.enable = true;
      };
    testScript = { nodes, ... }: ''
      start_all()

      default.wait_for_unit("multi-user.target")
      default.wait_for_unit("uptime-kuma.service")
      default.wait_for_unit("nginx.service")

      default.wait_until_succeeds("curl --fail http://127.0.0.1/dashboard", 20)
    '';
  });
}
