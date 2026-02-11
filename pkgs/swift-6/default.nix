{
  lib,
  stdenvNoCC,
  coreutils,
  gnugrep,
  swift-6-source,
}:

let
  swiftOs = "macosx";
  swiftArch = stdenvNoCC.hostPlatform.darwinArch;
  swiftModuleSubdir = "lib/swift/${swiftOs}";
  swiftLibSubdir = "lib/swift/${swiftOs}";
  swiftStaticModuleSubdir = "lib/swift_static/${swiftOs}";
  swiftStaticLibSubdir = "lib/swift_static/${swiftOs}";
in
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
      swift-symbolgraph-extract \
      clang \
      clang++ \
      clang-17
    do
      cp -a "${swift-6-source}/bin/$bin" "$out/bin/"
    done

    # Libraries
    cp -r ${swift-6-source}/lib/* $out/lib/

    runHook postInstall
  '';

  dontFixup = true;

  passthru = {
    inherit
      swiftOs
      swiftArch
      swiftModuleSubdir
      swiftLibSubdir
      swiftStaticModuleSubdir
      swiftStaticLibSubdir
      ;
    _wrapperParams = {
      coreutils_bin = lib.getBin coreutils;
      gnugrep_bin = gnugrep;
      suffixSalt = lib.replaceStrings [ "-" "." ] [ "_" "_" ] stdenvNoCC.targetPlatform.config;
      use_response_file_by_default = 0;
      swiftDriver = "";
    };
  };

  meta = with lib; {
    description = "Swift programming language compiler (unwrapped)";
    homepage = "https://swift.org";
    license = licenses.asl20;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
