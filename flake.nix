{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
		flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
		npmlock2nix.url = "github:nix-community/npmlock2nix";
		npmlock2nix.flake = false;
	};

	outputs =
		{ self, nixpkgs, flake-utils, flake-compat, npmlock2nix }:

		flake-utils.lib.eachDefaultSystem (system:
			let
				pkgs = nixpkgs.legacyPackages.${system}.extend (self: super: {
					npmlock2nix = super.callPackage "${npmlock2nix}/internal-v2.nix" { nodejs-16_x = nixpkgs.nodejs_18; };
				});
				packageJSON = builtins.fromJSON (builtins.readFile ./package.json);
				prettierPlugins = packageJSON.prettier.plugins;
			in
			{
				packages = rec {
					node_modules = pkgs.npmlock2nix.node_modules {
						src = self;
						nodejs = pkgs.nodejs;
					};
					default =
						let
							prettierPluginPaths = map (plugin: "${node_modules}/node_modules/${plugin}/lib/index.js") prettierPlugins;
							prettierPluginFlags = builtins.concatStringsSep " " (map (x: "--plugin ${x}") prettierPluginPaths);
						in
							pkgs.writeShellScriptBin "prettier" ''
								${node_modules}/bin/prettier ${prettierPluginFlags} "$@"
							'';
				};
				devShell = pkgs.mkShell {
					packages = with pkgs; [
						nodejs
					];
				};
			}
		);
}
