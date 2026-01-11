# Overlays for fixing macOS app signature issues
final: prev:
let
  # Helper function to fix macOS app signature issues
  fixMacAppSignature =
    name:
    prev.${name}.overrideAttrs (oldAttrs: {
      dontFixup = true;
    });

  # List of packages that need signature fixes
  fixMacAppTargets = [
    "aerospace"
    "discord"
    "scroll-reverser"
    "spotify"
  ];

  # Generate attribute set of signature-fixed packages
  signatureFixedPackages = builtins.listToAttrs (
    builtins.map (name: {
      inherit name;
      value = fixMacAppSignature name;
    }) fixMacAppTargets
  );
in
signatureFixedPackages
// (prev.lib.optionalAttrs (prev ? zen-browser) {
  zen-browser = fixMacAppSignature "zen-browser";
})
