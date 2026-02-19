{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
  _7zz,
  writeShellScript,
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

      releaseURL = "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest";
    in
    writeShellScript "obsidian-update-script" ''
      set -euo pipefail

      PATH=${path}

      # Resolve source.json path from repo root via UPDATE_NIX_ATTR_PATH
      # nix-update runs scripts with cwd=<repo root> and sets UPDATE_NIX_ATTR_PATH
      sourceJson="pkgs/''${UPDATE_NIX_ATTR_PATH}/source.json"

      # Fetch latest version
      newVersion=$(
        curl -sSfL "${releaseURL}" \
          | jq -r '.tag_name | ltrimstr("v")'
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
      url="https://github.com/obsidianmd/obsidian-releases/releases/download/v''${newVersion}/Obsidian-''${newVersion}.dmg"
      sha256=$(nix hash convert --hash-algo sha256 $(nix-prefetch-url "$url"))
      jq \
        --arg version "$newVersion" \
        --arg sha256 "$sha256" \
        '.version = $version | .sha256 = $sha256' \
        "$sourceJson" > "$sourceJson.tmp"
      mv "$sourceJson.tmp" "$sourceJson"
    '';

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
