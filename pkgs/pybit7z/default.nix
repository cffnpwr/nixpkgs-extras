{
  lib,
  pkgs,
  stdenv,
  buildPythonPackage,
  fetchurl,
  autoPatchelfHook,
  importlib-metadata,
  writeShellScript,
}:

let
  source = builtins.fromJSON (builtins.readFile ./source.json);

  wheel = source.wheels.${stdenv.hostPlatform.system};
in
buildPythonPackage {
  pname = "pybit7z";
  inherit (source) version;
  format = "wheel";

  src = fetchurl {
    inherit (wheel) url hash;
  };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  dependencies = [ importlib-metadata ];

  pythonImportsCheck = [ "pybit7z" ];

  passthru.updateScript = writeShellScript "pybit7z-update-script" ''
    exec ${pkgs.python3}/bin/python3 ${./update.py} "$@"
  '';

  meta = {
    description = "Python bindings for bit7z, a C++ static library offering 7-zip compression/extraction";
    homepage = "https://github.com/msclock/pybit7z";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cffnpwr ];
  };
}
