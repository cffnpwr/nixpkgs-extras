{ pkgs, ... }:
{
  claude = pkgs.callPackage ./claude { };
  fusuma = pkgs.callPackage ./fusuma { };
  google-japanese-ime = pkgs.callPackage ./google-japanese-ime { };
  kmonad = pkgs.callPackage ./kmonad { };
  microsoft-office = pkgs.lib.recurseIntoAttrs (pkgs.callPackage ./microsoft-office { });
  obsidian = pkgs.callPackage ./obsidian { };
  swiftPackages = pkgs.lib.recurseIntoAttrs {
    sourcekitd-inproc = pkgs.swiftPackages.callPackage ./sourcekitd-inproc { };
  };
  python3Packages = pkgs.lib.recurseIntoAttrs {
    pybit7z = pkgs.python3Packages.callPackage ./pybit7z { inherit pkgs; };
  };
  teams = pkgs.callPackage ./teams { };
}
