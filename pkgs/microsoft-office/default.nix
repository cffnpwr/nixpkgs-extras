{
  pkgs,
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  source = builtins.fromJSON (builtins.readFile ./source.json);
  inherit (source) version;

  src = fetchurl {
    url = "https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/Microsoft_365_and_Office_${version}_Installer.pkg";
    inherit (source) sha256;
  };

  frameworks = import ./frameworks.nix;
  proofingTools = import ./proofing-tools.nix;
  fonts = import ./fonts.nix;

  # Install helper script
  # Copies only the specified resources from the package to the app bundle
  # Arguments:
  #   list: List of resource names to copy
  #   $1: Source package directory
  #   $2: Destination app path
  #   $3: Source directory name within package (e.g., "Frameworks", "Proofing Tools", "DFonts")
  #   $4: Destination subpath within Contents (e.g., "Frameworks", "SharedSupport/Proofing Tools", "Resources/DFonts")
  mkCopyResources =
    list:
    pkgs.writeShellScript "copy-resources" ''
      set -euo pipefail

      srcPkg="$1"
      appPath="$2"
      srcDir="$3"
      destPath="$4"

      # Use ditto --clone on macOS 14.0+ to preserve signatures and metadata
      # This mimics the official installer's behavior
      ditto_cmd="/usr/bin/ditto"
      if [[ "$(/usr/bin/sw_vers -productVersion | cut -d. -f1)" -ge 14 ]]; then
        ditto_cmd="''${ditto_cmd} --clone"
      fi

      echo "Processing $srcDir..."
      pushd "$srcPkg"
      ${pkgs.gzip}/bin/zcat Payload | ${pkgs.cpio}/bin/cpio -id 2>/dev/null

      # Copy only specified frameworks
      mkdir -p "''${appPath}/Contents/''${destPath}"
      ${lib.concatMapStringsSep "\n" (item: ''
        $ditto_cmd "''${srcDir}/${item}" "''${appPath}/Contents/''${destPath}/${item}"
        echo "Copied ''${srcDir}: ${item}"
      '') list}
      popd
    '';

  mkOfficeApp =
    {
      pname,
      appName,
      pkgName,
      frameworks ? [ ],
      proofingTools ? [ ],
      fonts ? [ ],
      meta,
    }:
    stdenvNoCC.mkDerivation {
      inherit pname version src;

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

        # Extract Main App
        if [ -d "${pkgName}" ]; then
          cd "${pkgName}"
          zcat Payload | cpio -id 2>/dev/null
          # Use ditto instead of mv to preserve signatures
          $ditto_cmd "${appName}" "$out/Applications/${appName}"
          cd ..
        else
          echo "Error: ${pkgName} not found"
          exit 1
        fi

        appPath="$out/Applications/${appName}"

        ${mkCopyResources frameworks} "Office_frameworks.pkg" "$appPath" "Frameworks" "Frameworks"
        ${mkCopyResources proofingTools} "Office_proofing.pkg" "$appPath" "Proofing Tools" "SharedSupport/Proofing Tools"
        ${mkCopyResources fonts} "Office_fonts.pkg" "$appPath" "DFonts" "Resources/DFonts"

        runHook postInstall
      '';

      installCheckPhase = ''
        runHook preInstallCheck

        # Verify that the app is correctly codesigned
        /usr/bin/codesign -v "$out/Applications/${appName}"

        runHook postInstallCheck
      '';

      dontFixup = true;

      meta =
        with lib;
        {
          homepage = "https://www.microsoft.com/microsoft-365";
          license = licenses.unfree;
          platforms = platforms.darwin;
          maintainers = with maintainers; [ cffnpwr ];
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
    pkgName = "Microsoft_Word_Internal.pkg";
    frameworks = frameworks.word;
    proofingTools = proofingTools.word;
    fonts = fonts.word;
    meta.description = "Microsoft Word";
  };

  excel = mkOfficeApp {
    pname = "microsoft-excel";
    appName = "Microsoft Excel.app";
    pkgName = "Microsoft_Excel_Internal.pkg";
    frameworks = frameworks.excel;
    proofingTools = proofingTools.excel;
    fonts = fonts.excel;
    meta.description = "Microsoft Excel";
  };

  powerpoint = mkOfficeApp {
    pname = "microsoft-powerpoint";
    appName = "Microsoft PowerPoint.app";
    pkgName = "Microsoft_PowerPoint_Internal.pkg";
    frameworks = frameworks.powerpoint;
    proofingTools = proofingTools.powerpoint;
    fonts = fonts.powerpoint;
    meta.description = "Microsoft PowerPoint";
  };

  outlook = mkOfficeApp {
    pname = "microsoft-outlook";
    appName = "Microsoft Outlook.app";
    pkgName = "Microsoft_Outlook_Internal.pkg";
    frameworks = frameworks.outlook;
    proofingTools = proofingTools.outlook;
    fonts = fonts.outlook;
    meta.description = "Microsoft Outlook";
  };

  onenote = mkOfficeApp {
    pname = "microsoft-onenote";
    appName = "Microsoft OneNote.app";
    pkgName = "Microsoft_OneNote_Internal.pkg";
    frameworks = frameworks.onenote;
    proofingTools = proofingTools.onenote;
    fonts = fonts.onenote;
    meta.description = "Microsoft OneNote";
  };

  onedrive = mkOfficeApp {
    pname = "microsoft-onedrive";
    appName = "OneDrive.app";
    pkgName = "OneDrive.pkg";
    meta.description = "Microsoft OneDrive";
  };
}
