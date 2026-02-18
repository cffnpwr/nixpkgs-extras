{
  lib,
  stdenv,
  fetchgit,
  haskellPackages,
  writeShellScriptBin,
}:

let
  source = builtins.fromJSON (builtins.readFile ./source.json);

  src = fetchgit {
    url = "https://github.com/kmonad/kmonad";
    rev = source.rev;
    sha256 = source.sha256;
    fetchSubmodules = true;
  };

  fakeGit = writeShellScriptBin "git" ''
    echo ${src.rev}
  '';
in
haskellPackages.mkDerivation {
  pname = "kmonad";
  inherit (source) version;
  inherit src;

  license = lib.licenses.mit;

  isLibrary = true;
  isExecutable = true;

  # Haskell dependencies from cabal2nix output
  libraryHaskellDepends =
    with haskellPackages;
    [
      base
      cereal
      hashable
      lens
      megaparsec
      mtl
      optparse-applicative
      resourcet
      rio
      template-haskell
      time
      transformers
      unix
      unliftio
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      hinotify
    ];

  executableHaskellDepends = with haskellPackages; [ base ];

  testHaskellDepends = with haskellPackages; [
    base
    hspec
    rio
  ];

  testToolDepends = with haskellPackages; [ hspec-discover ];

  configureFlags = lib.optional stdenv.hostPlatform.isDarwin "--flag=dext";

  buildTools = [ fakeGit ];

  preConfigure = lib.optionalString stdenv.hostPlatform.isDarwin ''
    if [ ! -d c_src/mac/Karabiner-DriverKit-VirtualHIDDevice/include ]; then
      echo "Karabiner submodule not found. This package needs to be built with submodules on darwin." 1>&2
      exit 1
    fi
  '';

  description = "Advanced keyboard remapping utility";
  homepage = "https://github.com/kmonad/kmonad";
  platforms = lib.platforms.unix;
  mainProgram = "kmonad";
}
