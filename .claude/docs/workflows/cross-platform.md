# Cross-Platform Development Guide

## Platform Detection

Use `pkgs.stdenv` for platform checks:

```nix
pkgs.stdenv.isDarwin  # true on macOS
pkgs.stdenv.isLinux   # true on Linux
```

## Platform-Specific Implementations

### Using lib.mkMerge

```nix
config = lib.mkIf cfg.enable (lib.mkMerge [
  {
    # Common configuration
  }
  (lib.mkIf pkgs.stdenv.isDarwin {
    # macOS-specific configuration
  })
  (lib.mkIf pkgs.stdenv.isLinux {
    # Linux-specific configuration
  })
]);
```

### Using lib.optionalAttrs

```nix
config = lib.mkIf cfg.enable {
  # Common configuration
} // lib.optionalAttrs pkgs.stdenv.isDarwin {
  # macOS-specific configuration
};
```

## Cross-Platform Device Configuration

For device paths that differ between platforms, use a submodule pattern:

```nix
device = lib.mkOption {
  type = lib.types.either lib.types.str (
    lib.types.submodule {
      options = {
        linux = lib.mkOption {
          type = lib.types.str;
          description = "Device path on Linux";
        };
        darwin = lib.mkOption {
          type = lib.types.str;
          description = "Device path on macOS";
        };
      };
    }
  );
  description = "Device path (string for same on both platforms, or attrset for platform-specific)";
};
```

Usage in config:

```nix
let
  devicePath =
    if builtins.isString cfg.device
    then cfg.device
    else if pkgs.stdenv.isDarwin
    then cfg.device.darwin
    else cfg.device.linux;
in
# Use devicePath
```
