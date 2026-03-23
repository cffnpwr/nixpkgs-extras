# nixpkgs-extras

[![GitHub License](https://img.shields.io/github/license/cffnpwr/nixpkgs-extras?style=flat)](./LICENSE)

Custom Nix packages and modules for cffnpwr.

[日本語版のREADMEはこちら](./README-ja.md)

## Provided Outputs

### Packages

| Package               | Link                                                                                               |
| --------------------- | -------------------------------------------------------------------------------------------------- |
| `claude`              | [Claude Desktop](https://claude.ai)                                                                |
| `fusuma`              | [Fusuma](https://github.com/iberianpig/fusuma)                                                     |
| `google-japanese-ime` | [Google Japanese IME](https://www.google.co.jp/ime/)                                               |
| `kmonad`              | [KMonad](https://github.com/kmonad/kmonad)                                                         |
| `microsoft-office`    | [Microsoft Office for macOS](https://www.microsoft.com/microsoft-365/mac/microsoft-office-for-mac) |
| `obsidian`            | [Obsidian](https://obsidian.md)                                                                    |
| `teams`               | [Microsoft Teams](https://www.microsoft.com/microsoft-teams/)                                      |

### Overlays

Packages available via `overlays.default`:

| Package           | Link                                                       |
| ----------------- | ---------------------------------------------------------- |
| `lefthook`        | [Lefthook](https://github.com/evilmartians/lefthook)       |
| `scroll-reverser` | [Scroll Reverser](https://pilotmoon.com/scrollreverser/)   |
| `swiftformat`     | [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) |
| `swiftlint`       | [SwiftLint](https://github.com/realm/SwiftLint)            |
| `zed-editor`      | [Zed](https://zed.dev)                                     |

### Modules

| Module                         | Type                              | Description                                                                                                                                    |
| ------------------------------ | --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `programs.google-japanese-ime` | Home Manager                      | Declaratively configure [Google Japanese IME](https://www.google.co.jp/ime/) settings                                                          |
| `programs.kmonad`              | Home Manager / nix-darwin / NixOS | Manage [KMonad](https://github.com/kmonad/kmonad) keyboard                                                                                     |
| `programs.mas`                 | Home Manager                      | Install Mac App Store apps declaratively via [mas](https://github.com/mas-cli/mas)                                                             |
| `services.google-japanese-ime` | nix-darwin                        | Install and enable [Google Japanese IME](https://www.google.co.jp/ime/) as a system input method service                                       |
| `services.karabiner-dk`        | nix-darwin                        | Install and activate [Karabiner-DriverKit-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice) kernel extension |
| `services.kmonad`              | Home Manager / nix-darwin / NixOS | Run [KMonad](https://github.com/kmonad/kmonad) as a systemd/launchd service                                                                    |
| `system.defaults.inputsources` | nix-darwin                        | Configure third-party input sources (`AppleEnabledThirdPartyInputSources`) for macOS                                                           |

## How to Use

### Nix Flake Overlay

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
          # pkgs.lefthook, pkgs.swiftformat, etc. are now available
        }
      ];
    };
  };
}
```

### Home Manager Modules

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs-extras.url = "github:cffnpwr/nixpkgs-extras";
  };

  outputs = { nixpkgs, home-manager, nixpkgs-extras, ... }: {
    homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
      modules = [
        nixpkgs-extras.homeModules.default
        {
          programs.kmonad.enable = true;
        }
      ];
    };
  };
}
```

### nix-darwin Modules

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nixpkgs-extras.url = "github:cffnpwr/nixpkgs-extras";
  };

  outputs = { nixpkgs, nix-darwin, nixpkgs-extras, ... }: {
    darwinConfigurations.mymac = nix-darwin.lib.darwinSystem {
      modules = [
        nixpkgs-extras.darwinModules.default
        {
          services.google-japanese-ime.enable = true;
        }
      ];
    };
  };
}
```

### Binary Cache

A cache of pre-built binaries is available at `https://nix-cache.cffnpwr.dev`.

```nix
# flake.nix
{
  nixConfig = {
    extra-substituters = [ "https://nix-cache.cffnpwr.dev" ];
    extra-trusted-public-keys = [
      "cffnpwr-nixpkgs-extras:dmp2DUGwdqawLCPOsOcRxU/NpCO/qA1jha/8rmoSzvA="
    ];
  };
}
```

## License

[MIT License](./LICENSE)
