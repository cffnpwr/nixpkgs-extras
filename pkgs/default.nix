{ pkgs, ... }:
let
  swift-6-source = pkgs.callPackage ./swift-6/source.nix { };
  swift-6-unwrapped = pkgs.callPackage ./swift-6 { inherit swift-6-source; };
  swift-6-driver = pkgs.callPackage ./swift-6/swift-driver.nix { inherit swift-6-source; };
  swift6Packages = pkgs.lib.recurseIntoAttrs {
    swift-unwrapped = swift-6-unwrapped;
    swift = pkgs.callPackage ./swift-6/wrapper.nix {
      swift = swift-6-unwrapped;
      swift-driver = swift-6-driver;
      nixpkgsSwiftWrapperPath = "${pkgs.path}/pkgs/development/compilers/swift/wrapper";
    };
    swiftpm = pkgs.callPackage ./swift-6/swiftpm.nix { inherit swift-6-source; };
    lldb = pkgs.callPackage ./swift-6/lldb.nix { inherit swift-6-source; };
    sourcekit-lsp = pkgs.callPackage ./swift-6/sourcekit-lsp.nix { inherit swift-6-source; };
    llvm = pkgs.callPackage ./swift-6/llvm.nix { inherit swift-6-source; };
    swift-docc = pkgs.callPackage ./swift-6/docc.nix { inherit swift-6-source; };
    swift-driver = swift-6-driver;
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
