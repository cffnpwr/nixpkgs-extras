{
  pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  ...
}:
let
  _pnpm = pkgs.pnpm_10;

  # Install helper script
  # Uses `pnpm pack` to create a tarball of the built app and extracts it to the destination
  # Arguments:
  #   $1: package name
  #   $2: destination directory
  copyBuiltAppWithPnpmPack = pkgs.writeShellScript "copy-built-app-with-pnpm-pack" ''
    app="$1"
    dst="$2"

    echo "Packing $app..."

    # Use --pack-destination to specify output directory and avoid JSON parsing issues
    # pnpm pack creates a tarball with name pattern: <package-name>-<version>.tgz
    pack_dir=$(mktemp -d)
    trap 'rm -rf -- "$pack_dir"' EXIT
    ${_pnpm}/bin/pnpm --filter="$app" pack --pack-destination "$pack_dir" >/dev/null 2>&1

    # Find the created tarball using fd
    tarball=$(${pkgs.fd}/bin/fd -t f -e tgz . "$pack_dir" -x echo {} | head -n1)
    echo "Packed tarball: $tarball"

    # Extract the tarball to the destination directory
    mkdir -p "$dst"
    ${pkgs.gnutar}/bin/tar -xzf "$tarball" -C "$dst" --strip-components=1
  '';

  # Install helper script
  # Checks if the target path belongs to a workspace package
  # Arguments:
  #   $1: target path (can be resolved or direct)
  checkDependsOnWorkspacePackage = pkgs.writeShellScript "check-depends-on-workspace-package" ''
    target="$1"

    # Handle empty target (when readlink -f fails)
    [[ -z "$target" ]] && exit 1

    [[ "$target" == *"/apps/"* ]] || \
    [[ "$target" == *"/packages/"* ]] || \
    [[ "$target" == *"@file+apps+"* ]] || \
    [[ "$target" == *"@file+packages+"* ]] || \
    [[ "$target" == *"/source/"* ]]
  '';

  # Install helper script
  # Fixes symlink to workspace package
  # Arguments:
  #   $1: symlink path
  #   $2: output directory (for the parent package)
  fixSymlinkToWorkspacePackage = pkgs.writeShellScript "fix-symlink-to-workspace-package" ''
    symlink="$1"
    outDir="$2"

    # Extract full package name from symlink path
    # Examples:
    #   /path/node_modules/.pnpm/node_modules/@ccusage/mcp -> @ccusage/mcp
    #   /path/node_modules/.pnpm/node_modules/some-pkg -> some-pkg
    symlinkDir=$(dirname "$symlink")
    pkgName=$(basename "$symlink")

    # Check if this is a scoped package by examining the parent directory
    parentDir=$(basename "$symlinkDir")
    if [[ "$parentDir" == "@"* ]]; then
      # Scoped package: @scope/package
      pkgName="''${parentDir}/''${pkgName}"
    fi

    # Read package.json from the output directory to get the actual package name
    if [ -f "$outDir/package.json" ]; then
      actualPkgName=$(${pkgs.jq}/bin/jq -r '.name' "$outDir/package.json")

      # Check if this symlink points to the current package (self-reference)
      if [ "$pkgName" = "$actualPkgName" ]; then
        echo "  Fixing self-reference symlink: $symlink -> $outDir"
        realPath=$(${pkgs.coreutils}/bin/realpath --relative-to="$(dirname "$symlink")" "$outDir")
        rm "$symlink"
        ln -s "$realPath" "$symlink"
        exit 0
      fi
    fi

    # For other workspace packages, try to find them in sibling directories
    # Extract base name (without scope) to guess directory name
    baseDir=$(echo "$pkgName" | ${pkgs.gnused}/bin/sed 's/@.*\///')

    # Get the parent directory of outDir (e.g., /nix/store/.../mcp -> /nix/store/...)
    parentOutDir=$(dirname "$outDir")
    candidateDir="$parentOutDir/$baseDir"

    if [ -d "$candidateDir" ]; then
      # Verify this is the correct package by checking package.json
      if [ -f "$candidateDir/package.json" ]; then
        candidatePkgName=$(${pkgs.jq}/bin/jq -r '.name' "$candidateDir/package.json")

        if [ "$pkgName" = "$candidatePkgName" ]; then
          echo "  Replacing broken symlink $symlink -> $candidateDir (verified by package.json)"
          realPath=$(${pkgs.coreutils}/bin/realpath --relative-to="$(dirname "$symlink")" "$candidateDir")
          rm "$symlink"
          ln -s "$realPath" "$symlink"
          exit 0
        fi
      fi
    fi
  '';

  # Install helper script
  # Installs a built app and its dependencies
  # Arguments:
  #   $1: package name
  #   $2: package path
  #   $3: output directory
  installApp = pkgs.writeShellScript "install-ccusage-app" ''
    pkgName="$1"
    pkgPath="$2"
    outDir="$3"

    echo "Installing package: $pkgName from $pkgPath"

    # Use `pnpm deploy` to create an isolated build in a temporary directory.
    ${copyBuiltAppWithPnpmPack} "$pkgName" "$outDir"

    # If the app has dependencies, copy them
    if jq -e '.dependencies | length > 0' "''${pkgPath}/package.json"; then
      tmpDir=$(mktemp -d)
      trap 'rm -rf -- "$tmpDir"' EXIT

      echo "Copy dependencies for $pkgName..."
      # Get the pnpm store directory configured by pnpmConfigHook
      storeDir=$(${_pnpm}/bin/pnpm config get store-dir)
      echo "Using pnpm store: $storeDir"
      # Copy app to temporary directory isolatedly using pnpm deploy
      ${_pnpm}/bin/pnpm --filter="$pkgName" deploy --legacy --prod --store-dir="$storeDir" "$tmpDir"

      # Copy `node_modules` in the temporary directory to the output app directory
      echo "Copying node_modules to ''${outDir}..."
      cp -r "''${tmpDir}/node_modules" "''${outDir}/"

      # Fix symlinks to workspace packages
      echo "Fixing symlinks to workspace packages..."

      ${pkgs.fd}/bin/fd -t l -H . "''${outDir}/" | while read -r symlink; do
        directTarget=$(${pkgs.coreutils}/bin/readlink "$symlink")
        resolvedTarget=$(${pkgs.coreutils}/bin/readlink -f "$symlink" 2>/dev/null || echo "")

        # Check if the symlink points to a workspace package
        # Check both resolved and direct targets since readlink -f may fail
        if ${checkDependsOnWorkspacePackage} "$resolvedTarget" || ${checkDependsOnWorkspacePackage} "$directTarget"; then
          ${fixSymlinkToWorkspacePackage} "$symlink" "$outDir"
        fi
      done
    fi
  '';

  # pnpm dependencies hashes
  pnpmDepsHashes = {
    x86_64-linux = "sha256-+k0w4ojGhGKNNIVrGovj6lT3WbGnN8i8AthFJQiEZyQ=";
    aarch64-linux = "sha256-INZ1HCaCQmO0R3karASRj3dQ8CKs+L4QqdboedG+yLU=";
    x86_64-darwin = "sha256-trKg09EcUxTfet09UyRatRhUuHiSF6wpyVcDvsQ9mtE=";
    aarch64-darwin = "sha256-WY6LWQhLEKJVnI/028CPUqiH4DUyX0wTMmlY0tDfSS4=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ccusage";
  version = "17.2.0";

  src = fetchFromGitHub {
    owner = "ryoppippi";
    repo = "ccusage";
    rev = "v${finalAttrs.version}";
    hash = "sha256-3EHiNPQlvLQgkFRSGWhLuo31PVaNBGhpc9pa3VcR5tw=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = pnpmDepsHashes.${pkgs.stdenv.hostPlatform.system};
    pnpm = _pnpm;
  };

  nativeBuildInputs = with pkgs; [
    # Node.js and package manager
    nodejs_24
    pnpmConfigHook
    _pnpm

    # Development tools required by build scripts
    bun
    coreutils
    fd
    git
    jq
    makeWrapper
  ];

  configurePhase = ''
    runHook preConfigure

    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NODE_EXTRA_CA_CERTS="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

    runHook postConfigure
  '';

  preBuild = ''
    # Setup git (required by build scripts)
    git config --global user.name "ccusage-builder"
    git config --global user.email "ccusage-builder@example.com"

    git init
  '';

  buildPhase = ''
    runHook preBuild

    # Build all
    pnpm run --aggregate-output --reporter=append-only --stream build

    runHook postBuild
  '';

  preInstall = ''
    set -euo pipefail
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # Extract package names and paths
    pnpm --filter='./apps/**' ls -r --json --depth -1 | \
      jq -r '.[] | "\(.name)|\(.path)"' | \
    while IFS='|' read -r pkgName pkgPath; do
      pkgDir=$(basename "$pkgPath")
      ${installApp} "$pkgName" "$pkgPath" "$out/$pkgDir"
    done

    # Create wrappers for each CLI tool
    fd -t f package.json $out | while read -r packageJson; do
      appDir=$(dirname "$packageJson")
      echo "Processing $(jq -r '.name' "$packageJson") in ''${appDir}..."

      jq -r '(.bin // {}) | to_entries[] | "\(.key)|\(.value)"' "$packageJson" | \
      while IFS='|' read -r binName binPath; do
        binPath="$(realpath "''${appDir}/''${binPath}")"
        nodeModulesPath="''${appDir}/node_modules"

        cmd="makeWrapper ${pkgs.nodejs_24}/bin/node "''${out}/bin/''${binName}" --add-flag ''${binPath}"
        if [ -d "$nodeModulesPath" ]; then
          cmd="$cmd --set NODE_PATH ''${nodeModulesPath}"
        fi
        echo "Creating wrapper for $binName -> $binPath"
        eval "$cmd"
      done
    done

    runHook postInstall
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    # Test all binaries with --version
    for bin in $out/bin/*; do
      binName=$(basename "$bin")
      echo "Testing $binName --version..."

      # Run --version and check if it contains the version string
      if ! $bin --version | grep -q "${finalAttrs.version}"; then
        echo "Error: $binName --version does not contain version ${finalAttrs.version}"
        $bin --version || true
        exit 1
      fi

      echo "✓ $binName --version passed"
    done

    runHook postInstallCheck
  '';

  meta = {
    description = "A CLI tool for analyzing Claude Code/Codex CLI usage from JSONL files.";
    homepage = "https://github.com/ryoppippi/ccusage";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ cffnpwr ];
    mainProgram = "ccusage";
  };
})
