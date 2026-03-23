# lefthook overlay

[![GitHub License](https://img.shields.io/github/license/cffnpwr/nixpkgs-extras?style=flat)](../../../LICENSE)

[lefthook](https://github.com/evilmartians/lefthook)の複数バージョンを同時に提供するnixpkgs overlayです。

[README.md for English is available here](./README.md)

## How to Use

`cffnpwr/nixpkgs-extras`の`overlays.default`を適用するとoverlayが使用可能です。

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

### Example: devShells

```nix
devShells.default = pkgs.mkShell {
  buildInputs = [
    pkgs.lefthook.versions."2.1.4"
  ];
};
```

## Available Versions

v0.6.4以降が利用可能です。
全バージョンは [`manifests/`](./manifests/) を参照してください。
