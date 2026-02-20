# Command Reference

## Formatting

```bash
# Format all Nix files (uses nixfmt-rfc-style)
nix fmt

# Format specific file
nixfmt <file.nix>
```

## Building and Testing

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

## Platform-Specific Module Testing

```bash
# Test Home Manager module
nix build .#homeConfigurations.<config>.activationPackage

# Test nix-darwin module
nix build .#darwinConfigurations.<config>.system

# Test NixOS module
nix build .#nixosConfigurations.<config>.config.system.build.toplevel
```
