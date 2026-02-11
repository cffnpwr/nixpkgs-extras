{
  lib,
  stdenv,
  swift,
  swift-driver,
  useSwiftDriver ? true,
  nixpkgsSwiftWrapperPath,
}:

stdenv.mkDerivation (
  swift._wrapperParams
  // {
    pname = "swift-6-wrapper";
    inherit (swift) version;
    meta = swift.meta // {
      mainProgram = "swift";
    };

    inherit swift;
    inherit (swift)
      swiftOs
      swiftArch
      swiftModuleSubdir
      swiftLibSubdir
      swiftStaticModuleSubdir
      swiftStaticLibSubdir
      ;
    bintools = stdenv.cc.bintools;
    # Placeholder; overridden in buildCommand with a symlink for correct argv[0]
    swiftDriver = "";
    cc_wrapper = stdenv.cc.override (prev: {
      extraBuildCommands = prev.extraBuildCommands + ''
        rm -r $out/resource-root
        substituteInPlace $out/nix-support/cc-cflags \
          --replace-fail \
            "-resource-dir=$out/resource-root" \
            "-resource-dir=${lib.getLib swift}/lib/swift/clang"

        # Export MACOSX_DEPLOYMENT_TARGET so the Swift wrapper's -target triple
        # version matches -mmacos-version-min from cc-wrapper's add-flags.sh.
        echo 'export MACOSX_DEPLOYMENT_TARGET=''${MACOSX_DEPLOYMENT_TARGET:-${stdenv.targetPlatform.darwinMinVersion}}' \
          >> $out/nix-support/darwin-sdk-setup.bash
      '';
    });

    env.darwinMinVersion = lib.optionalString stdenv.targetPlatform.isDarwin (
      stdenv.targetPlatform.darwinMinVersion
    );

    passAsFile = [ "buildCommand" ];
    buildCommand = ''
      mkdir -p $out/bin $out/nix-support $out/libexec

      ln -s -t $out/bin/ $swift/bin/swift* $swift/bin/clang*

      ${lib.optionalString useSwiftDriver ''
          # swift-driver checks argv[0] to determine driver mode and rejects
          # "swift-driver" as invalid. We create a small wrapper that uses
          # "exec -a swiftc" so argv[0] is "swiftc" while @executable_path
          # still resolves to $out/bin/ (where clang and other tools live).
          rm -f $out/bin/swift-driver
          cp -a ${swift-driver}/bin/swift-driver $out/bin/swift-driver
          cat > $out/libexec/swiftc-driver <<WRAPPER
        #!${stdenv.shell}
        exec -a swiftc $out/bin/swift-driver "\$@"
        WRAPPER
          chmod +x $out/libexec/swiftc-driver
          export swiftDriver=$out/libexec/swiftc-driver
      ''}

      for executable in swift swiftc swift-frontend; do
        export prog=$swift/bin/$executable
        rm $out/bin/$executable
        substituteAll '${nixpkgsSwiftWrapperPath}/wrapper.sh' $out/bin/$executable
        chmod a+x $out/bin/$executable
      done

      ${lib.optionalString useSwiftDriver ''
        for bin in ${swift-driver}/bin/*; do
          name=$(basename "$bin")
          # swift-driver is already copied above; skip to avoid overwrite
          if [ "$name" != "swift-driver" ]; then
            rm -f $out/bin/$name
            cp -a "$bin" $out/bin/$name
          fi
        done
      ''}

      ln -s ${swift}/lib $out/lib

      substituteAll ${nixpkgsSwiftWrapperPath}/setup-hook.sh $out/nix-support/setup-hook

      if [ -e "$swift/nix-support" ]; then
        for input in "$swift/nix-support/"*propagated*; do
          cp "$input" "$out/nix-support/$(basename "$input")"
        done
      fi
    '';

    passthru = {
      inherit swift;
      inherit (swift)
        swiftOs
        swiftArch
        swiftModuleSubdir
        swiftLibSubdir
        ;
    };
  }
)
