{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
  ...
}:
let
  pname = "azookey";
  version = "0.1.3";
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/azooKey/azooKey-Desktop/releases/download/v${version}/azooKey-release-signed.pkg";
    sha256 = "sha256-eR03Ieky7sZib3Byc40kYuAVjVbuPNbuxe0vdmNIG9I=";
  };

  nativeBuildInputs = with pkgs; [
    xar
    gzip
    cpio
  ];

  unpackPhase = ''
    runHook preUnpack

    xar -xf $src
    zcat azooKey-tmp.pkg/Payload | cpio -idm

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Library/Input\ Methods
    cp -R azooKeyMac.app $out/Library/Input\ Methods/

    runHook postInstall
  '';

  # Don't modify binaries to preserve Apple code signing
  dontFixup = true;

  meta = with lib; {
    description = ''
      azooKey-Desktop is an open-source Japanese input method for macOS, written in Swift and powered by the Zenzai neural kana-kanji converter.
      It provides live conversion, optional LLM-based “Magic Conversions”, and Tuner-backed personalization for a smooth, desktop typing experience.
    '';
    homepage = "https://github.com/azooKey/azooKey-Desktop";
    license = licenses.mit;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ cffnpwr ];
  };
}
