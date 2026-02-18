{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
  xar,
  gzip,
  cpio,
}:

let
  source = builtins.fromJSON (builtins.readFile ./source.json);
in
stdenvNoCC.mkDerivation {
  pname = "google-japanese-ime";
  inherit (source) version;

  src = fetchurl {
    url = "https://dl.google.com/japanese-ime/latest/GoogleJapaneseInput.dmg";
    # Google doesn't provide stable URLs with hashes, hash may change when updated
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    undmg
    xar
    gzip
    cpio
  ];

  sourceRoot = ".";

  # Extract DMG, then .pkg, then payload
  unpackPhase = ''
    undmg $src
    mkdir -p pkg-extract
    cd pkg-extract
    ${xar}/bin/xar -xf ../GoogleJapaneseInput.pkg
    cd GoogleJapaneseInput.pkg
    ${gzip}/bin/zcat Payload | ${cpio}/bin/cpio -i
  '';

  installPhase = ''
    runHook preInstall

    # Copy extracted files preserving structure
    mkdir -p $out/{Library,Applications}
    cp -R Library $out/
    cp -R Applications/GoogleJapaneseInput.localized/*.app $out/Applications/

    runHook postInstall
  '';

  # Don't modify binaries to preserve Apple code signing
  dontFixup = true;

  meta = with lib; {
    description = "Google Japanese Input Method Editor";
    homepage = "https://www.google.co.jp/ime/";
    license = licenses.unfree;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
