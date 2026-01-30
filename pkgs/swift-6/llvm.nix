{
  lib,
  stdenvNoCC,
  swift-6-source,
}:

stdenvNoCC.mkDerivation {
  pname = "swift-6-llvm";
  inherit (swift-6-source) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib

    # Clang/LLVM binaries
    for bin in \
      clang \
      clang++ \
      clang-17 \
      clang-cache \
      clang-cl \
      clang-cpp \
      clangd \
      dsymutil \
      ld.lld \
      ld64.lld \
      lld \
      lld-link \
      llvm-ar \
      llvm-cov \
      llvm-objcopy \
      llvm-objdump \
      llvm-profdata \
      llvm-ranlib \
      llvm-symbolizer \
      wasm-ld
    do
      cp -a "${swift-6-source}/bin/$bin" "$out/bin/"
    done

    # Clang config files
    for cfg in \
      aarch64-swift-linux-musl-clang.cfg \
      aarch64-swift-linux-musl-clang++.cfg \
      x86_64-swift-linux-musl-clang.cfg \
      x86_64-swift-linux-musl-clang++.cfg
    do
      cp -a "${swift-6-source}/bin/$cfg" "$out/bin/"
    done

    # Libraries
    cp -a ${swift-6-source}/lib/libclang.dylib $out/lib/
    cp -a ${swift-6-source}/lib/libLTO.dylib $out/lib/
    cp -a ${swift-6-source}/lib/libIndexStore.dylib $out/lib/
    cp -r ${swift-6-source}/lib/clang $out/lib/

    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    description = "LLVM/Clang toolchain bundled with Swift";
    homepage = "https://swift.org";
    license = licenses.asl20;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      cffnpwr
    ];
  };
}
