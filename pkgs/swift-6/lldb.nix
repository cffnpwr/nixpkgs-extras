{
  lib,
  stdenvNoCC,
  swift-6-source,
}:

stdenvNoCC.mkDerivation {
  pname = "swift-6-lldb";
  inherit (swift-6-source) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib

    for bin in lldb lldb-dap; do
      cp -a "${swift-6-source}/bin/$bin" "$out/bin/"
    done

    cp -r ${swift-6-source}/System/Library/PrivateFrameworks/LLDB.framework $out/lib/

    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    description = "LLDB debugger for Swift";
    homepage = "https://swift.org";
    license = licenses.asl20;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
