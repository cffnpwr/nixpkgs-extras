{
  lib,
  swiftPackages,
}:

# Override nixpkgs swift-unwrapped to add sourcekit-inproc component and skip LLDB.
#
# sourcekit-inproc is not included in the macOS default install components
# (only sourcekit-xpc-service is). We use lib.replaceStrings on the already-
# evaluated buildPhase / installPhase strings because swiftInstallComponents is
# a local variable that has been inlined into those strings by the time
# overrideAttrs receives oldAttrs.
swiftPackages.swift-unwrapped.overrideAttrs (oldAttrs: {
  # Add sourcekit-inproc to install components
  buildPhase =
    let
      # Insert sourcekit-inproc next to sourcekit-xpc-service
      s1 =
        lib.replaceStrings
          [ "sourcekit-xpc-service;swift-remote-mirror" ]
          [ "sourcekit-xpc-service;sourcekit-inproc;swift-remote-mirror" ]
          (oldAttrs.buildPhase or "");
      # Skip LLDB build (not a direct dependency of sourcekit-inproc)
      s2 =
        lib.replaceStrings
          [ "buildProject lldb llvm-project/lldb" ]
          [ "echo 'Skipping LLDB (not needed for SourceKit)'" ]
          s1;
      # Skip swift-concurrency-backdeploy build (not needed at runtime)
      s3 =
        lib.replaceStrings
          [ "buildProject swift-concurrency-backdeploy swift" ]
          [ "echo 'Skipping swift-concurrency-backdeploy (not needed for SourceKit)'" ]
          s2;
    in
    s3;

  # Skip LLDB and swift-concurrency-backdeploy install steps
  installPhase =
    let
      s1 =
        lib.replaceStrings
          [ "cd $SWIFT_BUILD_ROOT/lldb\nninjaInstallPhase\n" ]
          [ "echo 'Skipping LLDB install'\n" ]
          (oldAttrs.installPhase or "");
      s2 =
        lib.replaceStrings
          [
            "cd $SWIFT_BUILD_ROOT/swift-concurrency-backdeploy\ninstallTargets=install-back-deployment\nninjaInstallPhase\nunset installTargets\n"
          ]
          [ "echo 'Skipping back-deployment install'\n" ]
          s1;
    in
    s2;

  cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
    "-DSWIFT_INCLUDE_TESTS=OFF"
    "-DSWIFT_INCLUDE_DOCS=OFF"
    "-DLLVM_ENABLE_ASSERTIONS=OFF"
    "-DLLVM_PARALLEL_LINK_JOBS=2"
  ];

  enableParallelBuilding = true;

  meta = oldAttrs.meta // {
    description = "Swift compiler with sourcekit-inproc component (without LLDB)";
  };
})
