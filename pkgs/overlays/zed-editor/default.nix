final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  zed-editor = prev.symlinkJoin {
    name = "zed-editor-${prev.zed-editor.version}";
    paths = [ prev.zed-editor ];
    nativeBuildInputs = [ prev.makeWrapper ];
    # On macOS, the CLI binary uses canonicalize() to locate Zed.app, which
    # resolves all symlinks and returns the nix store path. macOS Launch
    # Services cannot launch apps from /nix/store, causing the CLI to hang
    # indefinitely when given arguments.
    #
    # The --zed flag overrides the app bundle path passed to LSOpenFromURLSpec.
    # We probe candidate paths at runtime (in priority order):
    #   1. ~/Applications/Home Manager Apps/Zed.app  (Home Manager copyApps/linkApps)
    #   2. ~/Applications/Nix Apps/Zed.app            (nix-darwin system packages)
    # The first path that exists and contains a real bundle is used.
    postBuild = ''
      wrapProgram $out/bin/zeditor \
        --run '
          _zed_app=""
          for _candidate in \
            "$HOME/Applications/Home Manager Apps/Zed.app" \
            "$HOME/Applications/Nix Apps/Zed.app"; do
            if [ -d "$_candidate" ]; then
              _zed_app="$_candidate"
              break
            fi
          done
          if [ -n "$_zed_app" ]; then
            set -- --zed "$_zed_app" "$@"
          fi
          unset _zed_app _candidate
        '

      # Provide `zed` as the canonical macOS command name (official recommendation)
      ln -sf zeditor $out/bin/zed
    '';
    meta = prev.zed-editor.meta;
    passthru = prev.zed-editor.passthru or { };
  };
}
