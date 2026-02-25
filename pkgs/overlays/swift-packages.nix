final: prev: {
  swiftPackages = prev.swiftPackages // {
    sourcekitd-inproc = prev.swiftPackages.callPackage ../sourcekitd-inproc { };
  };
}
