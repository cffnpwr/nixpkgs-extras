{
  lib,
  stdenvNoCC,
  swift-6-source,
}:

stdenvNoCC.mkDerivation {
  pname = "swift-6-format";
  inherit (swift-6-source) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    cp -a ${swift-6-source}/bin/swift-format $out/bin/

    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    description = "Swift code formatter";
    homepage = "https://swift.org";
    license = licenses.asl20;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
