# lefthook overlay

[![GitHub License](https://img.shields.io/github/license/cffnpwr/nixpkgs-extras?style=flat)](../../../LICENSE)

A nixpkgs overlay that provides multiple versions of [lefthook](https://github.com/evilmartians/lefthook) simultaneously.

[日本語版のREADMEはこちら](./README-ja.md)

## How to Use

Apply `overlays.default` from `cffnpwr/nixpkgs-extras` to make the overlay available:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-extras.url = "github:cffnpwr/nixpkgs-extras";
  };

  outputs = { nixpkgs, nixpkgs-extras, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.overlays = [ nixpkgs-extras.overlays.default ];
        }
      ];
    };
  };
}
```

### Use the latest version

```nix
pkgs.lefthook
```

### Use a specific version

```nix
pkgs.lefthook.versions."1.0.0"
pkgs.lefthook.versions."2.1.4"
```

### Example: devShell

```nix
devShells.default = pkgs.mkShell {
  buildInputs = [
    pkgs.lefthook.versions."2.1.4"
  ];
};
```

## Available Versions

v0.6.4 and later. See [`manifests/`](./manifests/) for the full list.
