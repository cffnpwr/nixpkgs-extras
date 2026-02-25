{
  lib,
  stdenv,
  swiftPackages,
}:

let
  swiftUnwrapped = lib.callPackageWith { inherit lib swiftPackages; } ./swift-unwrapped.nix { };
in
stdenv.mkDerivation {
  pname = "sourcekitd-inproc";
  version = swiftPackages.swift-unwrapped.version;

  src = swiftUnwrapped;

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r ${swiftUnwrapped}/lib/sourcekitdInProc.framework $out/lib/

    runHook postInstall
  '';

  meta = with lib; {
    description = "sourcekitdInProc.framework extracted from Swift";
    license = licenses.asl20;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ cffnpwr ];
  };
}
