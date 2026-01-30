{
  pkgs,
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "swift-6-source";
  version = "6.2.3";

  src = fetchurl {
    url = "https://download.swift.org/swift-${version}-release/xcode/swift-${version}-RELEASE/swift-${version}-RELEASE-osx.pkg";
    hash = "sha256-we2Ez1QyhsVJyqzMR+C0fYxhw8j+284SBd7cvr52Aag=";
  };

  nativeBuildInputs = with pkgs; [
    cpio
    gzip
    xar
  ];

  unpackPhase = ''
    runHook preUnpack

    xar -xf $src
    zcat swift-${version}-RELEASE-osx-package.pkg/Payload | cpio -idm

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out/
    cp -r Developer $out/
    cp -r System $out/

    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    description = "Swift 6 unpacked source";
    homepage = "https://swift.org";
    license = licenses.asl20;
    platforms = platforms.darwin;
  };
}
