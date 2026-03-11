final: prev:
let
  source = builtins.fromJSON (builtins.readFile ./source.json);

  path =
    with prev;
    lib.makeBinPath [
      coreutils
      curlMinimal
      jq
      nix
    ];

  releaseAPI = "https://api.github.com/repos/pilotmoon/Scroll-Reverser/releases/latest";
in
{
  scroll-reverser = prev.scroll-reverser.overrideAttrs (oldAttrs: {
    inherit (source) version;
    src = final.fetchurl {
      url = "https://github.com/pilotmoon/Scroll-Reverser/releases/download/v${source.version}/ScrollReverser-${source.version}.zip";
      hash = source.hash;
    };

    # Enable unpack phase to properly extract with signature preservation
    dontUnpack = false;

    nativeBuildInputs = [ prev.unzip ];

    sourceRoot = ".";

    # Remove AppleDouble files (._*) that break code signature verification
    postUnpack = ''
      /usr/sbin/dot_clean .
    '';

    # Use cp -R (same as claude package) to preserve code signature
    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -r "Scroll Reverser.app" $out/Applications/

      runHook postInstall
    '';

    # Skip fixup phase to preserve signature
    dontFixup = true;

    # Add custom maintainer
    meta = oldAttrs.meta or { } // {
      maintainers = (oldAttrs.meta.maintainers or [ ]) ++ [ final.lib.maintainers.cffnpwr ];
    };

    passthru = (oldAttrs.passthru or { }) // {
      updateScript = prev.writeShellScript "scroll-reverser-update-script" ''
        set -euo pipefail

        PATH=${path}

        sourceJson="pkgs/overlays/scroll-reverser/source.json"

        # Fetch latest version
        newVersion=$(
          curl -sSfL "${releaseAPI}" \
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

        # Compute new hash
        echo "Updating: $sourceJson"
        url="https://github.com/pilotmoon/Scroll-Reverser/releases/download/v''${newVersion}/ScrollReverser-''${newVersion}.zip"
        hash=$(nix hash convert --hash-algo sha256 $(nix-prefetch-url "$url"))

        # Update source.json
        jq \
          --arg version "$newVersion" \
          --arg hash "$hash" \
          '.version = $version | .hash = $hash' \
          "$sourceJson" > "$sourceJson.tmp"
        mv "$sourceJson.tmp" "$sourceJson"
      '';
    };
  });
}
