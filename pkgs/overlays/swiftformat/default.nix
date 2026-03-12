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

  releaseAPI = "https://api.github.com/repos/nicklockwood/SwiftFormat/releases/latest";
in
{
  swiftformat = prev.swiftformat.overrideAttrs (oldAttrs: {
    inherit (source) version;
    src = prev.fetchFromGitHub {
      owner = "nicklockwood";
      repo = "SwiftFormat";
      rev = source.version;
      hash = source.hash;
    };

    passthru = (oldAttrs.passthru or { }) // {
      updateScript = prev.writeShellScript "swiftformat-update-script" ''
        set -euo pipefail

        PATH=${path}

        sourceJson="pkgs/overlays/swiftformat/source.json"

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
        hash=$(nix hash convert --hash-algo sha256 $(
          nix-prefetch-url --unpack \
            "https://github.com/nicklockwood/SwiftFormat/archive/refs/tags/''${newVersion}.tar.gz"
        ))

        # Update source.json
        jq \
          --arg version "$newVersion" \
          --arg hash "$hash" \
          '.version = $version | .hash = $hash' \
          "$sourceJson" > "$sourceJson.tmp"
        mv "$sourceJson.tmp" "$sourceJson"
      '';
    };

    meta = oldAttrs.meta or { } // {
      maintainers = (oldAttrs.meta.maintainers or [ ]) ++ [ final.lib.maintainers.cffnpwr ];
    };
  });
}
