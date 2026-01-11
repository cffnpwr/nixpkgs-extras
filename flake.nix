{
  description = "cffnpwr's personal nixpkgs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      nix-unit,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        nix-unit.modules.flake.default
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          lib,
          ...
        }:
        let
          libExports = import ./lib { inherit lib; };
          internalLib = libExports.internalLib;

          allPackages = import ./pkgs { inherit pkgs; };
        in
        {
          # Configure pkgs with overlays
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
            config.allowUnfree = true;
          };

          # Legacy packages (all packages from ./pkgs)
          legacyPackages = allPackages;

          # Formatter
          formatter = pkgs.nixfmt-rfc-style;

          # Development shell
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nil
              nixd
              nixfmt-rfc-style
            ];
          };

          # Applications
          apps = {
            generate-github-actions-matrix = {
              type = "app";
              program = import ./scripts/generate-github-actions-matrix.nix {
                inherit pkgs lib;
                flake = self;
              };
            };

            update-pkg = {
              type = "app";
              program = import ./scripts/update-pkg.nix {
                inherit pkgs lib allPackages;
              };
            };
          };

          # nix-unit configuration
          nix-unit = {
            # Collect all *.test.nix files
            tests = internalLib.testsFromDir ./.;
          };
        };

      flake =
        let
          lib = nixpkgs.lib;
          libExports = import ./lib { inherit lib; };
          internalLib = libExports.internalLib;

          # Helper to wrap modules with internalLib in extraSpecialArgs
          wrapModulesWithInternalLib = dir: {
            _module.args.internalLib = internalLib;
            imports = lib.collect builtins.isString (internalLib.modulePathsFromDir dir);
          };
        in
        {
          # Overlays
          overlays.default =
            final: prev:
            import ./pkgs {
              pkgs = final;
            }
            // (import ./pkgs/overlays.nix final prev)
            // {
              lib = prev.lib.extend (
                _: _: {
                  maintainers = (prev.lib.maintainers or { }) // internalLib.maintainers;
                }
              );
            };

          # Home Manager modules
          homeModules.default = wrapModulesWithInternalLib ./modules/home-manager;

          # nix-darwin modules
          darwinModules.default = wrapModulesWithInternalLib ./modules/darwin;

          # NixOS modules
          nixosModules.default = wrapModulesWithInternalLib ./modules/nixos;
        };
    };
}
