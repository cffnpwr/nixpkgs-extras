# Module Development Guide

## Creating a New Module

### 1. Choose the Right Location

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

### 2. Create the Module File

Create a new `.nix` file in the appropriate directory. Use kebab-case for filenames (e.g., `my-program.nix`).

### 3. Basic Module Template

```nix
{ config, lib, pkgs, internalLib, ... }:

let
  cfg = config.<namespace>.<module-name>;
in
{
  options.<namespace>.<module-name> = {
    enable = lib.mkEnableOption "<description>";
    package = lib.mkPackageOption pkgs "<package-name>" { };
    # ... more options
  };

  config = lib.mkIf cfg.enable {
    # ... implementation
  };
}
```

### 4. Namespace Conventions

| Module Type | Namespace |
|-------------|-----------|
| Home Manager programs | `programs.<name>` |
| Home Manager services | `services.<name>` |
| Darwin programs | `programs.<name>` |
| Darwin services | `services.<name>` |
| NixOS programs | `programs.<name>` |
| NixOS services | `services.<name>` |

### 5. Using internalLib

If your module needs helper functions:

1. Create helpers in `lib/programs/<module-name>/default.nix`
2. Access via `internalLib.<module-name>.mkHelpers pkgs`

## Splitting Complex Modules

For modules with many options, split across multiple files:

```
modules/home-manager/programs/my-program/
├── default.nix      # Main entry with imports
├── settings.nix     # Settings options
└── files.nix        # File generation options
```

**default.nix**:
```nix
{ ... }:
{
  imports = [
    ./settings.nix
    ./files.nix
  ];
}
```

Each imported file defines options under the same namespace.
