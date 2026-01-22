# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is nixpkgs-extras, a repository that provides custom packages not available in nixpkgs, along with Home Manager modules, nix-darwin modules, and NixOS modules. The repository is structured as a Nix Flake.

## Flake Architecture

The flake exports several types of outputs:
- **overlays.default**: Package overlays that extend nixpkgs
- **homeModules**: Modules for Home Manager configuration
- **darwinModules**: Modules for nix-darwin configuration (macOS)
- **nixosModules**: Modules for NixOS configuration
- **packages**: Platform-specific packages for all supported systems
- **formatter**: Uses nixfmt-rfc-style (RFC 166)
- **devShells.default**: Development environment with git, nil, nixd, and nixfmt-rfc-style

### Supported Systems
- x86_64-linux
- aarch64-linux
- x86_64-darwin
- aarch64-darwin

## Internal Library System

The repository uses a custom internal library system (`internalLib`) defined in `lib/default.nix`:

1. **modulesFromDir**: A function that recursively collects Nix modules from a directory
   - Automatically imports `.nix` files and directories with `default.nix`
   - Skips `default.nix` files in the root of the search
   - Returns an attribute set of modules keyed by filename (without .nix extension)

2. **internalLib**: Contains helper functions organized by program/module name
   - Example: `internalLib.kmonad.mkHelpers pkgs` provides KMonad-specific helper functions
   - These helpers are passed to modules via `_module.args.internalLib` in flake.nix

3. **Library programs**: Located in `lib/programs/`, these provide:
   - Helper functions (e.g., `mkHelpers`) for creating configuration files
   - Option definitions (e.g., `mkKeyboardOptions`, `mkKmonadOptions`)
   - Platform-specific logic encapsulation

## Module Architecture

Modules are organized by target system and category:

```
modules/
├── home-manager/    # User-level configuration
│   ├── programs/    # User programs (package + config)
│   └── services/    # User services (daemons/agents)
├── darwin/          # macOS system-level configuration
│   ├── programs/
│   └── services/
└── nixos/           # Linux system-level configuration
    ├── programs/
    └── services/
```

### Module Pattern

All modules receive `internalLib` as an argument via `_module.args`:

```nix
{ config, lib, pkgs, internalLib, ... }:

let
  cfg = config.<namespace>.<module-name>;
  helpers = internalLib.<module-name>.mkHelpers pkgs;  # If applicable
in
{
  options.<namespace>.<module-name> = {
    enable = lib.mkEnableOption "<description>";
    # ... more options
  };

  config = lib.mkIf cfg.enable {
    # ... implementation
  };
}
```

### Complex Module Organization

Complex modules (like claude-code) are split across multiple files:
- `default.nix`: Main entry point with `imports` list
- `settings.nix`, `files.nix`, etc.: Specific concerns
- Each file defines a subset of options under the same namespace

## Development Commands

### Formatting
```bash
# Format all Nix files (uses nixfmt-rfc-style)
nix fmt

# Format specific file
nixfmt <file.nix>
```

### Building and Testing
```bash
# Enter development shell
nix develop

# Build a specific package
nix build .#<package-name>

# Verify flake structure
nix flake check

# Show flake outputs
nix flake show

# Update flake inputs
nix flake update
```

### Platform-Specific Module Testing
```bash
# Test Home Manager module
nix build .#homeConfigurations.<config>.activationPackage

# Test nix-darwin module
nix build .#darwinConfigurations.<config>.system

# Test NixOS module
nix build .#nixosConfigurations.<config>.config.system.build.toplevel
```

## Coding Conventions

### Naming
- Options: camelCase (e.g., `enable`, `extraArgs`)
- Variables: camelCase (e.g., `cfg`, `helpers`)
- Files: kebab-case (e.g., `karabiner-dk.nix`)
- Functions: camelCase (e.g., `mkHelpers`, `mkConfigFile`)

### Platform-Specific Code
Use `pkgs.stdenv.isDarwin` and `pkgs.stdenv.isLinux` for platform checks. Provide platform-specific implementations using `lib.mkMerge` or conditional logic within the module.

### Cross-Platform Device Configuration
For device paths that differ between platforms, use a submodule pattern:
```nix
device = lib.mkOption {
  type = lib.types.either lib.types.str (
    lib.types.submodule {
      options = {
        linux = lib.mkOption { ... };
        darwin = lib.mkOption { ... };
      };
    }
  );
};
```

## EditorConfig
The repository has `.editorconfig` with:
- Indentation: 2 spaces (except Go files which use tabs)
- Charset: utf-8
- End of line: lf
- Trim trailing whitespace: true
- Insert final newline: true
