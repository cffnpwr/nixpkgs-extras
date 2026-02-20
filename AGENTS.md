# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Summary

Custom Nix packages and modules not available in nixpkgs. Provides **Home Manager**, **nix-darwin**, and **NixOS** modules as a Nix Flake.

**Supported Systems**: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin

## Essential Commands

```bash
nix fmt                    # Format all Nix files
nix build .#<package>      # Build a package
nix flake check            # Verify flake structure
```

**Full command reference**: `.claude/docs/reference/commands.md`

## Task Navigation

### Creating Modules
**Task**: Add new program or service module

-> Read: `.claude/docs/workflows/module-development.md`

### Cross-Platform Development
**Task**: Handle platform-specific implementations

-> Read: `.claude/docs/workflows/cross-platform.md`

### Understanding Architecture
**Task**: Learn internalLib, module patterns

-> Read: `.claude/docs/reference/architecture.md`

## Project Structure

### Repository Layout

```
.
├── flake.nix            # Flake configuration
├── lib/                 # Internal library (internalLib)
│   ├── default.nix      # modulesFromDir, internalLib definitions
│   └── programs/        # Program-specific helpers
├── modules/             # Nix modules
│   ├── home-manager/    # User-level (programs/, services/)
│   ├── darwin/          # macOS system-level
│   └── nixos/           # Linux system-level
├── pkgs/                # Custom packages
└── .claude/             # Claude Code documentation
```

### Flake Outputs

| Output | Description |
|--------|-------------|
| `overlays.default` | Package overlays |
| `homeModules` | Home Manager modules |
| `darwinModules` | nix-darwin modules |
| `nixosModules` | NixOS modules |
| `packages` | Platform-specific packages |

## Coding Conventions

### Naming

- **Options/Variables**: camelCase (`enable`, `extraArgs`, `cfg`)
- **Files**: kebab-case (`karabiner-dk.nix`)
- **Functions**: camelCase (`mkHelpers`, `mkConfigFile`)

### Platform Detection

```nix
pkgs.stdenv.isDarwin  # macOS
pkgs.stdenv.isLinux   # Linux
```

## EditorConfig

- Indentation: 2 spaces
- Charset: utf-8
- End of line: lf
- Trim trailing whitespace: true
- Insert final newline: true
