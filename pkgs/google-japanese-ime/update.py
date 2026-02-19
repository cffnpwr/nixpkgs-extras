#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p "python3" "_7zz" "xar.lib"
"""Update script for google-japanese-ime package.

Extracts the version from the DMG's embedded PackageInfo using 7zz (to unpack
the DMG) and libxar (via ctypes), then updates source.json with the new
version and sha256.

Works on any platform (no hdiutil/macOS-specific tools required).
"""

import base64
import ctypes
import ctypes.util
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import urllib.request
from pathlib import Path
from xml.etree import ElementTree

DOWNLOAD_URL = "https://dl.google.com/japanese-ime/latest/GoogleJapaneseInput.dmg"
BUNDLE_ID = "com.google.inputmethod.Japanese"

_XAR_READ = 0


def _load_libxar() -> ctypes.CDLL:
    libpath = ctypes.util.find_library("xar")
    if libpath is None:
        raise RuntimeError("libxar not found; ensure xar.lib is in the environment")
    lib = ctypes.CDLL(libpath)

    lib.xar_open.restype = ctypes.c_void_p
    lib.xar_open.argtypes = [ctypes.c_char_p, ctypes.c_int32]

    lib.xar_close.restype = ctypes.c_int
    lib.xar_close.argtypes = [ctypes.c_void_p]

    lib.xar_iter_new.restype = ctypes.c_void_p
    lib.xar_iter_new.argtypes = []

    lib.xar_iter_free.restype = None
    lib.xar_iter_free.argtypes = [ctypes.c_void_p]

    lib.xar_file_first.restype = ctypes.c_void_p
    lib.xar_file_first.argtypes = [ctypes.c_void_p, ctypes.c_void_p]

    lib.xar_file_next.restype = ctypes.c_void_p
    lib.xar_file_next.argtypes = [ctypes.c_void_p]

    lib.xar_get_path.restype = ctypes.c_char_p
    lib.xar_get_path.argtypes = [ctypes.c_void_p]

    lib.xar_extract_tobuffersz.restype = ctypes.c_int32
    lib.xar_extract_tobuffersz.argtypes = [
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_char_p),
        ctypes.POINTER(ctypes.c_size_t),
    ]

    return lib


def _extract_from_xar(pkg_path: Path, target_path: str) -> bytes:
    """Extract a single file from a XAR archive and return its contents."""
    lib = _load_libxar()

    x = lib.xar_open(str(pkg_path).encode(), _XAR_READ)
    if not x:
        raise RuntimeError(f"xar_open failed for {pkg_path}")

    try:
        it = lib.xar_iter_new()
        if not it:
            raise RuntimeError("xar_iter_new failed")
        try:
            f = lib.xar_file_first(x, it)
            while f:
                path = lib.xar_get_path(f)
                if path and path.decode() == target_path:
                    buf = ctypes.c_char_p(None)
                    size = ctypes.c_size_t(0)
                    ret = lib.xar_extract_tobuffersz(
                        x, f, ctypes.byref(buf), ctypes.byref(size)
                    )
                    if ret != 0:
                        raise RuntimeError(
                            f"xar_extract_tobuffersz failed (ret={ret})"
                        )
                    data = ctypes.string_at(buf, size.value)
                    # libxar allocates this buffer with malloc; free it
                    libc = ctypes.CDLL(ctypes.util.find_library("c"))
                    libc.free(buf)
                    return data
                f = lib.xar_file_next(it)
        finally:
            lib.xar_iter_free(it)
    finally:
        lib.xar_close(x)

    raise RuntimeError(f"File {target_path!r} not found in {pkg_path}")


def fetch_version(tmpdir: Path) -> str:
    dmg_path = tmpdir / "GoogleJapaneseInput.dmg"
    print(f"Downloading {DOWNLOAD_URL} ...")
    urllib.request.urlretrieve(DOWNLOAD_URL, dmg_path)

    # Extract .pkg from DMG using 7zz
    pkg_out = tmpdir / "dmg-extracted"
    pkg_out.mkdir()
    sevenzip = shutil.which("7zz")
    if sevenzip is None:
        raise RuntimeError("7zz not found; ensure _7zz is in the environment")
    subprocess.run(
        [
            sevenzip,
            "x",
            str(dmg_path),
            f"-o{pkg_out}",
            "GoogleJapaneseInput/GoogleJapaneseInput.pkg",
            "-y",
        ],
        check=True,
        capture_output=True,
    )

    # Extract PackageInfo from .pkg using libxar via ctypes
    pkg_file = pkg_out / "GoogleJapaneseInput" / "GoogleJapaneseInput.pkg"
    package_info_data = _extract_from_xar(pkg_file, "GoogleJapaneseInput.pkg/PackageInfo")

    # Parse PackageInfo XML
    root = ElementTree.fromstring(package_info_data)
    for bundle in root.iter("bundle"):
        if bundle.get("id") == BUNDLE_ID:
            version = bundle.get("CFBundleShortVersionString")
            if version:
                return version

    raise RuntimeError(
        f"Could not find version for bundle id {BUNDLE_ID!r} in PackageInfo"
    )


def compute_sha256(url: str) -> str:
    """Download url and return its SHA-256 hash in SRI format (sha256-<base64>)."""
    with urllib.request.urlopen(url) as resp:
        digest = hashlib.file_digest(resp, "sha256")
    return "sha256-" + base64.b64encode(digest.digest()).decode()


def main() -> None:
    attr_path = os.environ.get("UPDATE_NIX_ATTR_PATH", "google-japanese-ime")
    source_json = Path("pkgs") / attr_path / "source.json"

    current = json.loads(source_json.read_text())
    current_version = current["version"]
    print(f"Current version: {current_version}")

    with tempfile.TemporaryDirectory() as tmpdir:
        new_version = fetch_version(Path(tmpdir))

    print(f"Latest version:  {new_version}")

    if new_version == current_version:
        print("No updates detected")
        return

    print(f"Updating: {source_json}")
    sha256 = compute_sha256(DOWNLOAD_URL)

    current["version"] = new_version
    current["sha256"] = sha256
    source_json.write_text(json.dumps(current, indent=2) + "\n")
    print("Done.")


if __name__ == "__main__":
    main()
