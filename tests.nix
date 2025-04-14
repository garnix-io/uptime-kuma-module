{ self }:
let
  pkgs = import self.inputs.nixpkgs { system = "x86_64-linux"; };
  garnix-lib = self.inputs.garnix-lib;
in {
  x86_64-linux.simple = pkgs.testers.runNixOSTest ({ lib, ... }: {
    name = "uptime-kuma";
    nodes.simple = { lib, pkgs, ... }:
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

      simple.wait_for_unit("multi-user.target")
      simple.wait_for_unit("uptime-kuma.service")
      simple.wait_for_unit("nginx.service")

      simple.wait_until_succeeds("curl --fail http://127.0.0.1/dashboard", 20)
    '';
  });
}
