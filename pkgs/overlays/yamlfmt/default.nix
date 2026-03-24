final: prev:
let
  lib = prev.lib;

  manifestDir = ./manifests;
  manifestFiles = builtins.readDir manifestDir;
  manifests =
    lib.mapAttrs'
      (
        name: _:
        let
          version = lib.strings.removeSuffix ".json" name;
          data = builtins.fromJSON (builtins.readFile (manifestDir + "/${name}"));
        in
        lib.nameValuePair version data
      )
      (
        lib.filterAttrs (name: type: type == "regular" && lib.strings.hasSuffix ".json" name) manifestFiles
      );

  mkYamlfmtVersion =
    data:
    let
      src = prev.fetchFromGitHub {
        owner = "google";
        repo = "yamlfmt";
        rev = "v${data.version}";
        hash = data.hash;
      };
      go = prev.go-bin.fromGoMod "${src}/go.mod";
    in
    prev.yamlfmt.overrideAttrs (oldAttrs: {
      inherit src;
      inherit (data) version;
      vendorHash = data.vendorHash;
      nativeBuildInputs =
        map (p: if lib.isDerivation p && p.pname or "" == "go" then go else p) (
          oldAttrs.nativeBuildInputs or [ ]
        )
        ++ (
          if
            !(lib.any (p: lib.isDerivation p && p.pname or "" == "go") (oldAttrs.nativeBuildInputs or [ ]))
          then
            [ go ]
          else
            [ ]
        );
    });

  versions = lib.mapAttrs (_: mkYamlfmtVersion) manifests;

  latestVersion = lib.last (lib.naturalSort (lib.attrNames manifests));

  path =
    with prev;
    lib.makeBinPath [
      coreutils
      curlMinimal
      go
      jq
      nix
    ];

  releaseAPI = "https://api.github.com/repos/google/yamlfmt/releases/latest";
in
{
  yamlfmt = (mkYamlfmtVersion manifests.${latestVersion}).overrideAttrs (oldAttrs: {
    passthru = (oldAttrs.passthru or { }) // {
      inherit versions;
      latest = versions.${latestVersion};
      updateScript = prev.writeShellScript "yamlfmt-update-script" ''
        set -euo pipefail

        PATH=${path}

        manifestsDir="pkgs/overlays/yamlfmt/manifests"

        # Fetch latest version
        newVersion=$(
          curl -sSfL "${releaseAPI}" \
            | jq -r '.tag_name | ltrimstr("v")'
        )

        # Find current version (latest manifest)
        currentVersion=$(ls "$manifestsDir"/*.json | sort -V | tail -1 | jq -Rr 'split("/")[-1] | split(".json")[0]')
        echo "Current version: $currentVersion"
        echo "Latest version:  $newVersion"

        manifestFile="$manifestsDir/''${newVersion}.json"
        if [ -f "$manifestFile" ]; then
          echo "No updates detected"
          exit 0
        fi

        # Compute source hash and store path
        echo "Updating: $manifestFile"
        prefetchResult=$(nix flake prefetch "github:google/yamlfmt/v''${newVersion}" --json)
        hash=$(echo "$prefetchResult" | jq -r '.hash')
        storePath=$(echo "$prefetchResult" | jq -r '.storePath')

        # Compute vendorHash via go mod vendor + nix hash path
        tmpDir=$(mktemp -d)
        cp -r "''${storePath}/." "$tmpDir/"
        chmod -R +w "$tmpDir"
        vendorHash=$(cd "$tmpDir" && go mod vendor 2>/dev/null && nix hash path vendor)
        rm -rf "$tmpDir"

        # Write manifest
        jq -n \
          --arg version "$newVersion" \
          --arg hash "$hash" \
          --arg vendorHash "$vendorHash" \
          '{version: $version, hash: $hash, vendorHash: $vendorHash}' \
          > "$manifestFile"

      '';
    };
    meta = oldAttrs.meta or { } // {
      maintainers = (oldAttrs.meta.maintainers or [ ]) ++ [ final.lib.maintainers.cffnpwr ];
    };
  });
}
