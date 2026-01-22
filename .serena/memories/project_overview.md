# Project Overview

## Purpose
This is nixpkgs-extras (`cffnpwr's nixpkgs-extras`) that provides custom packages not available in nixpkgs:
- Custom packages (overlays)
- Home Manager modules
- nix-darwin modules
- NixOS modules

## Project Type
Nix Flake-based repository providing reusable modules and packages for NixOS, macOS (nix-darwin), and Home Manager.

## Tech Stack
- **Language**: Nix
- **Build System**: Nix Flakes
- **Dependencies**:
  - nixpkgs (nixpkgs-unstable)
  - lib-aggregate (nix-community)
  - flake-compat (nix-community)

## Repository Structure
```
.
├── flake.nix          # Main flake definition
├── default.nix        # Flake compatibility wrapper
├── shell.nix          # Development shell
├── lib/               # Internal library functions
│   ├── default.nix
│   ├── maintainers.nix
│   └── programs/      # Program-specific helpers
├── pkgs/              # Custom packages
├── modules/
│   ├── home-manager/  # Home Manager modules
│   │   ├── programs/  # User programs configuration
│   │   └── services/  # User services (daemons/agents)
│   ├── darwin/        # nix-darwin modules
│   │   ├── programs/
│   │   └── services/
│   └── nixos/         # NixOS modules
│       ├── programs/
│       └── services/
└── docs/              # Documentation files
```

## Flake Outputs
- `overlays.default`: Package overlays
- `homeModules`: Home Manager modules
- `darwinModules`: nix-darwin modules
- `nixosModules`: NixOS modules
- `packages`: Platform-specific packages
- `formatter`: nixfmt-rfc-style
- `devShells.default`: Development environment
