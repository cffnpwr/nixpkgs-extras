{
  lib,
  pkgs,
  stdenv,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  zlib,
  openssl,
  git,
  writeShellScript,
}:

let
  source = builtins.fromJSON (builtins.readFile ./source.json);

  binary = source.binaries.${stdenv.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "apm";
  inherit (source) version;

  src = fetchurl {
    inherit (binary) url hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    zlib
    openssl
  ];

  # PyInstaller onedir bundles must keep their layout; stripping breaks them.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    bundle=$(echo apm-*)
    mkdir -p $out/libexec
    cp -r "$bundle" $out/libexec/apm

    makeWrapper $out/libexec/apm/apm $out/bin/apm \
      --prefix PATH : ${lib.makeBinPath [ git ]}

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
    in
    writeShellScript "apm-update-script" ''
      set -euo pipefail

      PATH=${path}

      # nix-update runs scripts with cwd=<repo root> and sets UPDATE_NIX_ATTR_PATH
      sourceJson="pkgs/''${UPDATE_NIX_ATTR_PATH}/source.json"

      latestTag=$(curl -sSfL https://api.github.com/repos/microsoft/apm/releases/latest | jq -r .tag_name)
      newVersion=''${latestTag#v}

      currentVersion=$(jq -r .version "$sourceJson")
      echo "Current version: $currentVersion"
      echo "Latest version:  $newVersion"
      if [ "$newVersion" = "$currentVersion" ]; then
        echo "No updates detected"
        exit 0
      fi

      echo "Updating: $sourceJson"

      declare -A assets=(
        [aarch64-darwin]=apm-darwin-arm64.tar.gz
        [aarch64-linux]=apm-linux-arm64.tar.gz
        [x86_64-linux]=apm-linux-x86_64.tar.gz
      )

      tmp=$(mktemp)
      jq --arg v "$newVersion" '.version = $v' "$sourceJson" > "$tmp"

      for sys in "''${!assets[@]}"; do
        asset=''${assets[$sys]}
        url="https://github.com/microsoft/apm/releases/download/v''${newVersion}/''${asset}"
        echo "  Fetching hash for $sys..."
        hash=$(nix store prefetch-file --json --name "$asset" "$url" | jq -r .hash)
        jq --arg sys "$sys" --arg url "$url" --arg hash "$hash" \
          '.binaries[$sys] = { url: $url, hash: $hash }' "$tmp" > "$tmp.next"
        mv "$tmp.next" "$tmp"
      done

      mv "$tmp" "$sourceJson"
      echo "Done."
    '';

  meta = with lib; {
    description = "Agent Package Manager - dependency manager for AI agents";
    homepage = "https://github.com/microsoft/apm";
    license = licenses.mit;
    mainProgram = "apm";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
