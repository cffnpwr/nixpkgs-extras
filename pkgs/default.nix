{ pkgs, ... }:
let
  swift-6-source = pkgs.callPackage ./swift-6/source.nix { };
  swift6Packages = pkgs.lib.recurseIntoAttrs {
    swift = pkgs.callPackage ./swift-6 { inherit swift-6-source; };
    swiftpm = pkgs.callPackage ./swift-6/swiftpm.nix { inherit swift-6-source; };
    lldb = pkgs.callPackage ./swift-6/lldb.nix { inherit swift-6-source; };
    sourcekit-lsp = pkgs.callPackage ./swift-6/sourcekit-lsp.nix { inherit swift-6-source; };
    llvm = pkgs.callPackage ./swift-6/llvm.nix { inherit swift-6-source; };
    swift-docc = pkgs.callPackage ./swift-6/docc.nix { inherit swift-6-source; };
    swift-driver = pkgs.callPackage ./swift-6/swift-driver.nix { inherit swift-6-source; };
    swift-format = pkgs.callPackage ./swift-6/format.nix { inherit swift-6-source; };
  };
in
{
  claude = pkgs.callPackage ./claude { };
  fusuma = pkgs.callPackage ./fusuma { };
  google-japanese-ime = pkgs.callPackage ./google-japanese-ime { };
  kmonad = pkgs.callPackage ./kmonad { };
  microsoft-office = pkgs.lib.recurseIntoAttrs (pkgs.callPackage ./microsoft-office { });
  obsidian = pkgs.callPackage ./obsidian { };
  inherit swift6Packages;
  swift_6 = swift6Packages.swift;
  teams = pkgs.callPackage ./teams { };
}
