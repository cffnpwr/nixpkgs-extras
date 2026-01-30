{
  lib,
  stdenvNoCC,
  swift-6-source,
}:

stdenvNoCC.mkDerivation {
  pname = "swift-6-pm";
  inherit (swift-6-source) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    for bin in \
      swift-build \
      swift-build-tool \
      swift-experimental-sdk \
      swift-package \
      swift-package-collection \
      swift-package-registry \
      swift-plugin-server \
      swift-run \
      swift-sdk \
      swift-test
    do
      cp -a "${swift-6-source}/bin/$bin" "$out/bin/"
    done

    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    description = "Swift Package Manager";
    homepage = "https://swift.org";
    license = licenses.asl20;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
