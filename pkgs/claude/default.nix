{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
  unzip,
  writeShellScript,
}:

stdenvNoCC.mkDerivation rec {
  pname = "claude";
  version = "1.0.2339";

  src = fetchurl {
    url = "https://downloads.claude.ai/releases/darwin/universal/1.0.2339/Claude-1782e27bb4481b2865073bfb82a97b5b23554636.zip";
    sha256 = "sha256-EjmDGrxPsEppjQw3tlrJKD2v+B0q0Qmpv4TRCzC7y4E=";
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
          curlMinimal
          gnused
          jq
          nix
        ];

      updateInfoURL = "https://claude.ai/api/desktop/darwin/universal/zip/latest";
      fakeUserAgent = "claude-updater/1.0";

      script = writeShellScript "claude-update-script" ''
        set -euo pipefail

        PATH=${path}

        # Nix file path passed as argument
        nixFile="$1"

        # Fetch new release version and URL
        read -r newVersion url < <(
          curl -sSfL -A "${fakeUserAgent}" ${updateInfoURL} | jq -r '.version + " " + .url'
        )

        # Compare version
        # If fetched version matches current version, exit successfully
        echo "Current version: ${version}"
        echo "Latest version:  $newVersion"
        if [ "$newVersion" = "${version}" ]; then
          echo "No updates detected"
          exit 0
        fi

        # Update nix file
        echo "Updating file: $nixFile"
        sha256=$(nix hash convert --hash-algo sha256 $(nix-prefetch-url "$url"))
        sed -i "s|version = \".*\";|version = \"$newVersion\";|" "$nixFile"
        sed -i "s|sha256 = \".*\";|sha256 = \"$sha256\";|" "$nixFile"
        sed -i "s|url = \".*\";|url = \"$url\";|" "$nixFile"
      '';
    in
    [
      script
      ./default.nix
    ];

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
