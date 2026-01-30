{
  lib,
  stdenvNoCC,
  swift-6-source,
}:

stdenvNoCC.mkDerivation {
  pname = "swift-6-sourcekit-lsp";
  inherit (swift-6-source) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib

    cp -a ${swift-6-source}/bin/sourcekit-lsp $out/bin/

    # SourceKit frameworks
    cp -r ${swift-6-source}/lib/sourcekitd.framework $out/lib/
    cp -r ${swift-6-source}/lib/sourcekitdInProc.framework $out/lib/
    cp -a ${swift-6-source}/lib/libSwiftSourceKitClientPlugin.dylib $out/lib/
    cp -a ${swift-6-source}/lib/libSwiftSourceKitPlugin.dylib $out/lib/

    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    description = "SourceKit-LSP language server for Swift";
    homepage = "https://swift.org";
    license = licenses.asl20;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
