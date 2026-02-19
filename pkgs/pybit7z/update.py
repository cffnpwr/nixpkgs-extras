"""Update script for pybit7z package.

Fetches the latest version and wheel URLs/hashes from PyPI,
then updates source.json.
"""

import base64
import hashlib
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

PYPI_URL = "https://pypi.org/pypi/pybit7z/json"

# Map wheel filename patterns to Nix system names
PLATFORM_MAP = {
    r"manylinux.*x86_64": "x86_64-linux",
    r"manylinux.*aarch64": "aarch64-linux",
    r"macosx.*x86_64": "x86_64-darwin",
    r"macosx.*arm64": "aarch64-darwin",
}

EXPECTED_PLATFORMS = set(PLATFORM_MAP.values())


def compute_sri_hash(url: str) -> str:
    """Download url and return its SHA-256 hash in SRI format (sha256-<base64>)."""
    with urllib.request.urlopen(url) as resp:
        digest = hashlib.file_digest(resp, "sha256")
    return "sha256-" + base64.b64encode(digest.digest()).decode()


def fetch_pypi_data() -> dict:
    with urllib.request.urlopen(PYPI_URL) as resp:
        return json.load(resp)


def find_wheels(pypi_data: dict, version: str) -> dict[str, str]:
    """Find cp313 wheel URLs for each platform from PyPI release data."""
    wheels: dict[str, str] = {}

    release_files = pypi_data.get("releases", {}).get(version, [])
    if not release_files:
        # Fall back to urls (latest version)
        release_files = pypi_data.get("urls", [])

    for file_info in release_files:
        fn = file_info["filename"]
        if not fn.endswith(".whl"):
            continue
        if "cp313-cp313" not in fn:
            continue

        for pattern, nix_system in PLATFORM_MAP.items():
            if re.search(pattern, fn):
                wheels[nix_system] = file_info["url"]
                break

    return wheels


def main() -> None:
    attr_path = os.environ.get("UPDATE_NIX_ATTR_PATH", "pybit7z")
    source_json = Path("pkgs") / attr_path / "source.json"

    current = json.loads(source_json.read_text())
    current_version = current["version"]
    print(f"Current version: {current_version}")

    pypi_data = fetch_pypi_data()
    new_version = pypi_data["info"]["version"]
    print(f"Latest version:  {new_version}")

    if new_version == current_version:
        print("No updates detected")
        return

    print(f"Updating: {source_json}")

    wheel_urls = find_wheels(pypi_data, new_version)
    missing = EXPECTED_PLATFORMS - set(wheel_urls.keys())
    if missing:
        print(f"Error: missing wheels for platforms: {missing}", file=sys.stderr)
        sys.exit(1)

    wheels: dict[str, dict[str, str]] = {}
    for nix_system in sorted(wheel_urls.keys()):
        url = wheel_urls[nix_system]
        print(f"  Fetching hash for {nix_system}...")
        sri_hash = compute_sri_hash(url)
        wheels[nix_system] = {"url": url, "hash": sri_hash}

    result = {"version": new_version, "wheels": wheels}
    source_json.write_text(json.dumps(result, indent=2) + "\n")
    print("Done.")


if __name__ == "__main__":
    main()
