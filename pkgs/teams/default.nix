# fork by cffnpwr
# original: https://github.com/NixOS/nixpkgs/blob/7735258f8a8b809af52fc79ffe273040f0ee26a3/pkgs/by-name/te/teams/package.nix
{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
  xar,
  pbzx,
  cpio,
  writeShellScript,
}:
let
  source = builtins.fromJSON (builtins.readFile ./source.json);
in
stdenvNoCC.mkDerivation {
  pname = "teams";
  inherit (source) version;

  src = fetchurl {
    url = "https://statics.teams.cdn.office.net/production-osx/${source.version}/MicrosoftTeams.pkg";
    inherit (source) sha256;
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

  passthru.updateScript =
    let
      path =
        with pkgs;
        lib.makeBinPath [
          coreutils
          curlMinimal
          jq
          nix
        ];

      versionURL = "https://config.teams.microsoft.com/config/v1/MicrosoftTeams/50_1.0.0.0?environment=prod&audienceGroup=general&teamsRing=general&agent=TeamsBuilds";
    in
    writeShellScript "teams-update-script" ''
      set -euo pipefail

      PATH=${path}

      # Resolve source.json path from repo root via UPDATE_NIX_ATTR_PATH
      # nix-update runs scripts with cwd=<repo root> and sets UPDATE_NIX_ATTR_PATH
      sourceJson="pkgs/''${UPDATE_NIX_ATTR_PATH}/source.json"

      # Fetch latest version
      newVersion=$(
        curl -sSfL "${versionURL}" \
          | jq -r '.BuildSettings.WebView2Canary.macOS.latestVersion'
      )

      # Compare version
      currentVersion=$(jq -r '.version' "$sourceJson")
      echo "Current version: $currentVersion"
      echo "Latest version:  $newVersion"
      if [ "$newVersion" = "$currentVersion" ]; then
        echo "No updates detected"
        exit 0
      fi

      # Update source.json
      echo "Updating: $sourceJson"
      url="https://statics.teams.cdn.office.net/production-osx/''${newVersion}/MicrosoftTeams.pkg"
      sha256=$(nix hash convert --hash-algo sha256 $(nix-prefetch-url "$url"))
      jq \
        --arg version "$newVersion" \
        --arg sha256 "$sha256" \
        '.version = $version | .sha256 = $sha256' \
        "$sourceJson" > "$sourceJson.tmp"
      mv "$sourceJson.tmp" "$sourceJson"
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
