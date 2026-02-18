{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
}:

let
  source = builtins.fromJSON (builtins.readFile ./source.json);
in
stdenvNoCC.mkDerivation {
  pname = "obsidian";
  inherit (source) version;

  src = fetchurl {
    url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${source.version}/Obsidian-${source.version}.dmg";
    inherit (source) sha256;
  };

  nativeBuildInputs = [ _7zz ];

  sourceRoot = ".";

  unpackCmd = ''
    7zz x -xr'!*:com.apple.cs.Code*' $curSrc
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r Obsidian.app $out/Applications/

    runHook postInstall
  '';

  # Skip fixup phase to preserve signature
  dontFixup = true;

  meta = with lib; {
    description = "A powerful knowledge base on top of a local folder of plain text Markdown files";
    homepage = "https://obsidian.md";
    license = licenses.unfree;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
