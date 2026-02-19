{
  lib,
  stdenv,
  buildPythonPackage,
  fetchurl,
  autoPatchelfHook,
  importlib-metadata,
}:

let
  version = "0.4.0";

  wheels = {
    x86_64-linux = {
      filename = "pybit7z-${version}-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-0gaZZqJsL8uSRHXvtHuO3H3xaoR/KhngoUAV9S3hcAo=";
      url = "https://files.pythonhosted.org/packages/d0/f1/ff756b4561dcabc6917b8195d3d5248b2b52488a536c493e32c950f001ed/pybit7z-${version}-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
    };
    aarch64-linux = {
      filename = "pybit7z-${version}-cp313-cp313-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
      hash = "sha256-r2LYj3VzEvYWIa6NWdEGm2eo3p69JO2I78BzUvdgtCU=";
      url = "https://files.pythonhosted.org/packages/62/da/b1f7f8444acab3ae27592d8ddcd64899c0b967448dc08debade1aac7c539/pybit7z-${version}-cp313-cp313-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
    };
    x86_64-darwin = {
      filename = "pybit7z-${version}-cp313-cp313-macosx_10_15_x86_64.whl";
      hash = "sha256-5401EbCeLehAcyKpPDz5F9eDXB2VpLYJW2Qcdr59hag=";
      url = "https://files.pythonhosted.org/packages/87/da/976f1dfdaf7dd398fc0d4905a51b1859841fc2a7d8ccf72b980e644a7ee5/pybit7z-${version}-cp313-cp313-macosx_10_15_x86_64.whl";
    };
    aarch64-darwin = {
      filename = "pybit7z-${version}-cp313-cp313-macosx_11_0_arm64.whl";
      hash = "sha256-ikWD34VvgLP1HoqFa/otcvkiah63OYvoA0MNOIuSPik=";
      url = "https://files.pythonhosted.org/packages/7e/ba/daf2d3df0a93dca35dbb536ca09129e663d43a0104b5318b236c9337885b/pybit7z-${version}-cp313-cp313-macosx_11_0_arm64.whl";
    };
  };

  wheel = wheels.${stdenv.hostPlatform.system};
in
buildPythonPackage {
  pname = "pybit7z";
  inherit version;
  format = "wheel";

  src = fetchurl {
    inherit (wheel) url hash;
    name = wheel.filename;
  };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  dependencies = [ importlib-metadata ];

  pythonImportsCheck = [ "pybit7z" ];

  meta = {
    description = "Python bindings for bit7z, a C++ static library offering 7-zip compression/extraction";
    homepage = "https://github.com/msclock/pybit7z";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cffnpwr ];
  };
}
