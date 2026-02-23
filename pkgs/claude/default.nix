{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
  unzip,
  writeShellScript,
}:

let
  source = builtins.fromJSON (builtins.readFile ./source.json);
in
stdenvNoCC.mkDerivation {
  pname = "claude";
  inherit (source) version;

  src = fetchurl {
    inherit (source) url sha256;
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r Claude.app $out/Applications/

    runHook postInstall
  '';

  # Skip fixup phase to preserve signature
  dontFixup = true;

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

      updateInfoURL = "https://downloads.claude.ai/releases/darwin/universal/RELEASES.json";
    in
    writeShellScript "claude-update-script" ''
      set -euo pipefail

      PATH=${path}

      # Resolve source.json path from repo root via UPDATE_NIX_ATTR_PATH
      # nix-update runs scripts with cwd=<repo root> and sets UPDATE_NIX_ATTR_PATH
      sourceJson="pkgs/''${UPDATE_NIX_ATTR_PATH}/source.json"

      # Fetch new release version and URL
      read -r newVersion url < <(
        curl -sSfL ${updateInfoURL} | jq -r '. as $r | .releases[] | select(.version == $r.currentRelease) | .updateTo | .version + " " + .url'
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
      sha256=$(nix hash convert --hash-algo sha256 $(nix-prefetch-url "$url"))
      jq \
        --arg version "$newVersion" \
        --arg url "$url" \
        --arg sha256 "$sha256" \
        '.version = $version | .url = $url | .sha256 = $sha256' \
        "$sourceJson" > "$sourceJson.tmp"
      mv "$sourceJson.tmp" "$sourceJson"
    '';

  meta = with lib; {
    description = "Claude AI assistant desktop application";
    homepage = "https://claude.ai";
    license = licenses.unfree;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
