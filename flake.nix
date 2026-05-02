{
  description = "cffnpwr's nixpkgs-extras - custom packages not available in nixpkgs";

  nixConfig = {
    extra-substituters = [ "https://nix-cache.cffnpwr.dev" ];
    extra-trusted-public-keys = [
      "cffnpwr-nixpkgs-extras:dmp2DUGwdqawLCPOsOcRxU/NpCO/qA1jha/8rmoSzvA="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    go-overlay = {
      url = "github:purpleclay/go-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      go-overlay,
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
          pkgs,
          system,
          lib,
          ...
        }:
        let
          libExports = import ./lib { inherit lib; };
          internalLib = libExports.internalLib;

          allPackages = import ./pkgs { inherit pkgs; };

          # Plain nixpkgs without overlays, used to evaluate overlay package metadata
          # (existence checks, meta.platforms) without triggering circular evaluation.
          prevPkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          # Configure pkgs with overlays applied on top of prevPkgs
          _module.args.pkgs = prevPkgs.extend self.overlays.default;

          # Legacy packages (all packages from ./pkgs)
          legacyPackages = allPackages;

          # Packages (derivations only; excludes attrset packages like microsoft-office)
          # Also filter out packages not supported on the current system
          # Includes overlay packages (e.g. discord, spotify) in addition to
          # packages defined in pkgs/
          packages =
            (lib.filterAttrs (
              _: drv:
              lib.isDerivation drv
              && (!(drv ? meta.platforms) || lib.meta.availableOn pkgs.stdenv.hostPlatform drv)
            ) allPackages)
            // (builtins.listToAttrs (
              map
                (e: {
                  name = e.name;
                  value = pkgs.${e.name};
                })
                (
                  builtins.filter (e: lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.${e.name}) (
                    import ./pkgs/overlays/matrix.nix pkgs
                  )
                )
            ));

          # Formatter
          formatter = pkgs.nixfmt;

          # Development shell
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nil
              nixd
              nixfmt
              treefmt
              yamlfmt
            ];
          };

          # Applications
          apps = {
            generate-github-actions-matrix = {
              type = "app";
              program = import ./scripts/generate-github-actions-matrix.nix {
                inherit pkgs lib allPackages;
                flake = self;
                overlayPackages = import ./pkgs/overlays/matrix.nix prevPkgs;
              };
            };

            update-pkg = {
              type = "app";
              program = import ./scripts/update-pkg.nix {
                inherit pkgs lib allPackages;
                overlayPackages =
                  let
                    matrixEntries = import ./pkgs/overlays/matrix.nix pkgs;
                    updatableNames = map (e: e.name) (builtins.filter (e: e.updatable) matrixEntries);
                  in
                  builtins.listToAttrs (
                    map (name: {
                      inherit name;
                      value = pkgs.${name};
                    }) updatableNames
                  );
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
            let
              prevWithGo = prev // (go-overlay.overlays.default final prev);
            in
            import ./pkgs {
              pkgs = final;
            }
            // (import ./pkgs/overlays final prevWithGo)
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
