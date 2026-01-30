{
  lib,
  stdenvNoCC,
  swift-6-source,
}:

stdenvNoCC.mkDerivation {
  pname = "swift-6";
  inherit (swift-6-source) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib

    # Core compiler binaries
    for bin in \
      swift \
      swiftc \
      swift-frontend \
      swift-driver \
      swift-help \
      swift-demangle \
      swift-api-digester \
      swift-api-checker.py \
      swift-autolink-extract \
      swift-build-sdk-interfaces \
      swift-cache-tool \
      swift-stdlib-tool \
      swift-symbolgraph-extract
    do
      cp -a "${swift-6-source}/bin/$bin" "$out/bin/"
    done

    # Libraries
    cp -r ${swift-6-source}/lib/* $out/lib/

    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    description = "Swift programming language compiler";
    homepage = "https://swift.org";
    license = licenses.asl20;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
