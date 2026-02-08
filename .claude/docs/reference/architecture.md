# Architecture Reference

## Internal Library System

The repository uses a custom internal library system (`internalLib`) defined in `lib/default.nix`.

### modulesFromDir

A function that recursively collects Nix modules from a directory:

- Automatically imports `.nix` files and directories with `default.nix`
- Skips `default.nix` files in the root of the search
- Returns an attribute set of modules keyed by filename (without .nix extension)

### internalLib

Contains helper functions organized by program/module name:

- Example: `internalLib.kmonad.mkHelpers pkgs` provides KMonad-specific helper functions
- These helpers are passed to modules via `_module.args.internalLib` in flake.nix

### Library Programs

Located in `lib/programs/`, these provide:

- Helper functions (e.g., `mkHelpers`) for creating configuration files
- Option definitions (e.g., `mkKeyboardOptions`, `mkKmonadOptions`)
- Platform-specific logic encapsulation

## Module Pattern

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

## Complex Module Organization

Complex modules (like claude-code) are split across multiple files:

- `default.nix`: Main entry point with `imports` list
- `settings.nix`, `files.nix`, etc.: Specific concerns
- Each file defines a subset of options under the same namespace
