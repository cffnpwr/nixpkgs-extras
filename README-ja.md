# nixpkgs-extras

[![GitHub License](https://img.shields.io/github/license/cffnpwr/nixpkgs-extras?style=flat)](./LICENSE)

cffnpwrのためのカスタムNixパッケージとモジュール集。

[README.md for English is available here](./README.md)

## Provided Outputs

### Packages

| パッケージ            | リンク                                                                                             |
| --------------------- | -------------------------------------------------------------------------------------------------- |
| `claude`              | [Claude Desktop](https://claude.ai)                                                                |
| `fusuma`              | [Fusuma](https://github.com/iberianpig/fusuma)                                                     |
| `google-japanese-ime` | [Google日本語入力](https://www.google.co.jp/ime/)                                                  |
| `kmonad`              | [KMonad](https://github.com/kmonad/kmonad)                                                         |
| `microsoft-office`    | [Microsoft Office for macOS](https://www.microsoft.com/microsoft-365/mac/microsoft-office-for-mac) |
| `obsidian`            | [Obsidian](https://obsidian.md)                                                                    |
| `teams`               | [Microsoft Teams](https://www.microsoft.com/microsoft-teams/)                                      |

### Overlays

`overlays.default`経由で利用できるパッケージを以下に示す。

| パッケージ        | リンク                                                     |
| ----------------- | ---------------------------------------------------------- |
| `lefthook`        | [Lefthook](https://github.com/evilmartians/lefthook)       |
| `scroll-reverser` | [Scroll Reverser](https://pilotmoon.com/scrollreverser/)   |
| `swiftformat`     | [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) |
| `swiftlint`       | [SwiftLint](https://github.com/realm/SwiftLint)            |
| `zed-editor`      | [Zed](https://zed.dev)                                     |

### Modules

| モジュール                     | 種別                              | 説明                                                                                                                                       |
| ------------------------------ | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `programs.google-japanese-ime` | Home Manager                      | [Google日本語入力](https://www.google.co.jp/ime/)の設定を管理                                                                              |
| `programs.kmonad`              | Home Manager / nix-darwin / NixOS | [KMonad](https://github.com/kmonad/kmonad)のキーボード設定を管理                                                                           |
| `programs.mas`                 | Home Manager                      | [mas](https://github.com/mas-cli/mas)を使ってMac App StoreアプリをNixでインストール                                                        |
| `services.google-japanese-ime` | nix-darwin                        | [Google日本語入力](https://www.google.co.jp/ime/)をシステムの入力メソッドサービスとしてインストール・有効化                                |
| `services.karabiner-dk`        | nix-darwin                        | [Karabiner-DriverKit-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice)カーネル拡張をインストール・有効化 |
| `services.kmonad`              | Home Manager / nix-darwin / NixOS | [KMonad](https://github.com/kmonad/kmonad)をsystemd/launchdサービスとして起動                                                              |
| `system.defaults.inputsources` | nix-darwin                        | macOSのサードパーティ入力ソース（`AppleEnabledThirdPartyInputSources`）を設定                                                              |

## How to use

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
          # pkgs.lefthook, pkgs.swiftformat などが利用可能になる
        }
      ];
    };
  };
}
```

### Home Manager Module

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

### nix-darwin Module

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

### Bineary Cache

`https://nix-cache.cffnpwr.dev`でビルド済みバイナリのキャッシュを提供しています。

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
