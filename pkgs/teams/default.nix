# fork by cffnpwr
# original: https://github.com/NixOS/nixpkgs/blob/7735258f8a8b809af52fc79ffe273040f0ee26a3/pkgs/by-name/te/teams/package.nix
{
  lib,
  stdenvNoCC,
  fetchurl,
  xar,
  pbzx,
  cpio,
}:
let
  pname = "teams";
  versions = {
    darwin = "26004.403.4267.4118";
  };
  hashes = {
    darwin = "sha256-BQXjmWehE8uqEo7aPAVSAU1eyoW1Y5D1GiZqeL8Fl3M=";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname;
  version = versions.darwin;

  src = fetchurl {
    url = "https://statics.teams.cdn.office.net/production-osx/${versions.darwin}/MicrosoftTeams.pkg";
    hash = hashes.darwin;
  };

  nativeBuildInputs = [
    xar
    pbzx
    cpio
  ];

  unpackPhase = ''
    runHook preUnpack

    xar -xf $src

    runHook postUnpack
  '';

  # Prevent fixup phase to preserve signature
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    workdir=$(pwd)
    APP_DIR=$out/Applications
    mkdir -p $APP_DIR
    cd $APP_DIR
    pbzx -n "$workdir/MicrosoftTeams_app.pkg/Payload" | cpio -idm

    runHook postInstall
  '';

  meta = with lib; {
    description = "Microsoft Teams";
    homepage = "https://teams.microsoft.com";
    downloadPage = "https://teams.microsoft.com/downloads";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    maintainers = with maintainers; [
      tricktron
      cffnpwr
    ];
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "teams";
  };
}
