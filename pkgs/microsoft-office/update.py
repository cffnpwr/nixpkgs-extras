"""Update script for microsoft-office packages.

Fetches the latest version and download URLs from Microsoft AutoUpdate (MAU)
manifest XMLs, then updates source.json with new version, url, and sha256
for each app.

Works on any platform (no macOS-specific tools required).

Supports:
  - nix run .#update-pkg microsoft-office/word
    (UPDATE_NIX_ATTR_PATH="microsoft-office/word")
  - nix-update --flake legacyPackages.<system>.microsoft-office.word
    (UPDATE_NIX_ATTR_PATH="microsoft-office.word")

Regardless of which app triggers the update, all apps in source.json
are updated together since they share one source.json.
"""

import base64
import hashlib
import json
import os
import plistlib
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

MAU_CDN = (
    "https://res.public.onecdn.static.microsoft"
    "/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate"
)

# App key -> MAU Application ID
APP_IDS = {
    "word": "MSWD2019",
    "excel": "XCEL2019",
    "powerpoint": "PPT32019",
    "outlook": "OPIM2019",
    "onenote": "ONMC2019",
    "onedrive": "ONDR18",
}


def fetch_manifest(app_id: str) -> list[dict]:
    """Fetch and parse a MAU manifest plist for the given application ID."""
    url = f"{MAU_CDN}/0409{app_id}.xml"
    with urllib.request.urlopen(url) as resp:
        data = resp.read()
    return plistlib.loads(data)


def get_latest_info(manifest: list[dict]) -> dict:
    """Extract version and full updater URL from the first manifest entry."""
    entry = manifest[0]
    version = entry["Update Version"]
    # Office apps use FullUpdaterLocation; OneDrive only has Location
    url = entry.get("FullUpdaterLocation", entry.get("Location"))
    if url is None:
        raise RuntimeError(f"No download URL found in manifest entry: {entry}")
    return {"version": version, "url": url}


def compute_sha256(url: str) -> str:
    """Download url and return its SHA-256 hash in SRI format (sha256-<base64>)."""
    with urllib.request.urlopen(url) as resp:
        digest = hashlib.file_digest(resp, "sha256")
    return "sha256-" + base64.b64encode(digest.digest()).decode()


def resolve_source_json() -> Path:
    """Resolve source.json path from UPDATE_NIX_ATTR_PATH.

    Handles both "/" separator (update-pkg) and "." separator (nix-update).
    """
    attr_path = os.environ.get("UPDATE_NIX_ATTR_PATH", "microsoft-office")
    # Normalize separators: both "microsoft-office/word" and
    # "microsoft-office.word" should resolve to "microsoft-office"
    for sep in ("/", "."):
        if sep in attr_path:
            base_attr = attr_path.split(sep)[0]
            return Path("pkgs") / base_attr / "source.json"
    return Path("pkgs") / attr_path / "source.json"


def fetch_app_info(app_key: str, app_id: str) -> tuple[str, dict]:
    """Fetch manifest and extract latest info for one app. Returns (app_key, info)."""
    manifest = fetch_manifest(app_id)
    info = get_latest_info(manifest)
    return app_key, info


def prefetch_hash(app_key: str, url: str) -> tuple[str, str]:
    """Download and compute SHA-256 for one app. Returns (app_key, sha256)."""
    filename = url.rsplit("/", 1)[-1]
    print(f"  {app_key}: downloading {filename} ...")
    sha256 = compute_sha256(url)
    print(f"  {app_key}: sha256 = {sha256}")
    return app_key, sha256


def main() -> None:
    source_json = resolve_source_json()
    current = json.loads(source_json.read_text()) if source_json.exists() else {}

    # Phase 1: Fetch all MAU manifests in parallel
    print("Fetching latest versions from MAU manifests...")
    latest_info: dict[str, dict] = {}
    with ThreadPoolExecutor(max_workers=len(APP_IDS)) as pool:
        futures = {
            pool.submit(fetch_app_info, key, aid): key
            for key, aid in APP_IDS.items()
        }
        for future in as_completed(futures):
            app_key, info = future.result()
            latest_info[app_key] = info

    # Phase 2: Determine which apps need hash prefetch
    print("Comparing versions...")
    apps_to_update: dict[str, dict] = {}
    for app_key in APP_IDS:
        info = latest_info[app_key]
        current_app = current.get(app_key, {})
        old_ver = current_app.get("version", "(none)")
        new_ver = info["version"]
        if (
            new_ver == current_app.get("version", "")
            and info["url"] == current_app.get("url", "")
        ):
            print(f"  {app_key}: {old_ver} (up to date)")
        else:
            print(f"  {app_key}: {old_ver} -> {new_ver}")
            apps_to_update[app_key] = info

    if not apps_to_update:
        print("No updates detected")
        return

    # Phase 3: Prefetch hashes in parallel
    print(f"Downloading and hashing {len(apps_to_update)} package(s)...")
    hashes: dict[str, str] = {}
    with ThreadPoolExecutor(max_workers=len(apps_to_update)) as pool:
        futures = {
            pool.submit(prefetch_hash, key, info["url"]): key
            for key, info in apps_to_update.items()
        }
        for future in as_completed(futures):
            app_key, sha256 = future.result()
            hashes[app_key] = sha256

    # Phase 4: Build new source.json
    new_data: dict = {}
    for app_key in APP_IDS:
        if app_key in apps_to_update:
            info = apps_to_update[app_key]
            new_data[app_key] = {
                "version": info["version"],
                "url": info["url"],
                "sha256": hashes[app_key],
            }
        else:
            new_data[app_key] = current[app_key]

    print(f"Updating: {source_json}")
    source_json.write_text(json.dumps(new_data, indent=2) + "\n")
    print("Done.")


if __name__ == "__main__":
    main()
