{
  pkgs,
  lib,
  stdenvNoCC,
  fetchurl,
  writeShellScript,
  python3,
}:

let
  sources = builtins.fromJSON (builtins.readFile ./source.json);

  mkOfficeApp =
    {
      pname,
      appName,
      pkgName,
      sourceKey,
      meta,
    }:
    let
      source = sources.${sourceKey};
    in
    stdenvNoCC.mkDerivation {
      inherit pname;
      inherit (source) version;

      src = fetchurl {
        inherit (source) url sha256;
      };

      nativeBuildInputs = with pkgs; [
        xar
        gzip
        cpio
      ];

      unpackPhase = ''
        xar -xf $src
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/Applications

        # Use ditto --clone on macOS 14.0+ to preserve signatures and metadata
        # This mimics the official installer's behavior
        ditto_cmd="/usr/bin/ditto"
        if [[ "$(/usr/bin/sw_vers -productVersion | cut -d. -f1)" -ge 14 ]]; then
          ditto_cmd="/usr/bin/ditto --clone"
        fi

        # Extract app from sub-package
        if [ -d "${pkgName}" ]; then
          cd "${pkgName}"
          zcat Payload | cpio -id 2>/dev/null
          $ditto_cmd "${appName}" "$out/Applications/${appName}"
          cd ..
        else
          echo "Error: ${pkgName} not found"
          exit 1
        fi

        runHook postInstall
      '';

      installCheckPhase = ''
        runHook preInstallCheck

        # Verify that the app is correctly codesigned
        /usr/bin/codesign -v "$out/Applications/${appName}"

        runHook postInstallCheck
      '';

      dontFixup = true;

      passthru.updateScript = writeShellScript "${pname}-update-script" ''
        exec ${python3}/bin/python3 ${./update.py} "$@"
      '';

      meta =
        with lib;
        {
          homepage = "https://www.microsoft.com/microsoft-365";
          license = licenses.unfree;
          platforms = platforms.darwin;
          maintainers = with maintainers; [ cffnpwr ];
          updateGroup = "microsoft-office";
        }
        // meta;
    };

in
{
  meta = {
    platforms = lib.platforms.darwin;
  };

  word = mkOfficeApp {
    pname = "microsoft-word";
    appName = "Microsoft Word.app";
    pkgName = "Microsoft_Word.pkg";
    sourceKey = "word";
    meta.description = "Microsoft Word";
  };

  excel = mkOfficeApp {
    pname = "microsoft-excel";
    appName = "Microsoft Excel.app";
    pkgName = "Microsoft_Excel.pkg";
    sourceKey = "excel";
    meta.description = "Microsoft Excel";
  };

  powerpoint = mkOfficeApp {
    pname = "microsoft-powerpoint";
    appName = "Microsoft PowerPoint.app";
    pkgName = "Microsoft_PowerPoint.pkg";
    sourceKey = "powerpoint";
    meta.description = "Microsoft PowerPoint";
  };

  outlook = mkOfficeApp {
    pname = "microsoft-outlook";
    appName = "Microsoft Outlook.app";
    pkgName = "Microsoft_Outlook.pkg";
    sourceKey = "outlook";
    meta.description = "Microsoft Outlook";
  };

  onenote = mkOfficeApp {
    pname = "microsoft-onenote";
    appName = "Microsoft OneNote.app";
    pkgName = "Microsoft_OneNote.pkg";
    sourceKey = "onenote";
    meta.description = "Microsoft OneNote";
  };

  onedrive = mkOfficeApp {
    pname = "microsoft-onedrive";
    appName = "OneDrive.app";
    pkgName = "OneDrive.pkg";
    sourceKey = "onedrive";
    meta.description = "Microsoft OneDrive";
  };
}
