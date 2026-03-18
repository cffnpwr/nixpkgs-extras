# Fix zed-editor CLI hanging when invoked via the nixpkgs-installed `zeditor` command.
#
# Root cause:
#   The CLI binary uses `current_exe().canonicalize()` to find its app bundle path.
#   When installed via nixpkgs, the symlink chain resolves to:
#     /nix/store/<hash>/Applications/Zed.app/Contents/MacOS/cli
#   The CLI then passes this nix store path to macOS `LSOpenFromURLSpec`, which
#   either fails or launches the wrong Zed instance, leaving the IPC server
#   waiting forever.
#
# Fix:
#   Wrap `zeditor` with `--zed "$HOME/Applications/Home Manager Apps/Zed.app"`.
#   This tells the CLI to use the Home Manager-managed app bundle, which is a real
#   directory (not a symlink), so `canonicalize()` does not resolve into /nix/store,
#   and macOS Launch Services can launch it successfully.
#
#   `wrapProgram` (makeShellWrapper) is used intentionally over `makeBinaryWrapper`
#   because it generates a shell script where `$HOME` is expanded at runtime,
#   correctly handling the space-containing path "Home Manager Apps".

final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  zed-editor = prev.symlinkJoin {
    name = "zed-editor-${prev.zed-editor.version}";
    paths = [ prev.zed-editor ];
    nativeBuildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zeditor \
        --add-flags "--zed \"\$HOME/Applications/Home Manager Apps/Zed.app\""
    '';
    meta = prev.zed-editor.meta;
    passthru = prev.zed-editor.passthru or { };
  };
}
