#!/system/bin/sh
# Restore/repair the DSH development environment after an APK/runtime update.
#
# Runtime layer: selectively restores missing Android/Java toolchain files,
# launchers, shebang paths, pnpm shims, git remote helper symlinks, and the
# fabricated @vscode/ripgrep-android-arm64 package. It never overwrites a
# newer runtime with the whole archived toolchain.
#
# User layer: restores home workspace from the newest shared backup when the
# whole workspace is absent, restores JpgToPng from the shared export when
# missing, and copies missing DSH user content back from the shared backup:
# settings, home patch, user-global AGENTS.md, skills, agent presets,
# ~/.agents/skills, home-level tool configs (.gitconfig/.curlrc/.wgetrc/
# .npmrc), and every backed-up profile's user-owned files plus @dsh-android
# packages.
PREFIX="${TERMUX__PREFIX:-/data/user/0/com.dshmobile.shell/files/usr}"
HOME_DIR="${HOME:-/data/user/0/com.dshmobile.shell/files/home}"
LONG="/storage/emulated/0/DSH"
OLD="/data/data/com.termux/files/usr"
NEW="$PREFIX"
JDK="$PREFIX/lib/jvm/java-21-openjdk/bin"
TAR="$PREFIX/bin/tar"
[ -x "$TAR" ] || TAR=/system/bin/tar
GZIP="$PREFIX/bin/gzip"
[ -x "$GZIP" ] || GZIP=/system/bin/gzip

echo "== DSH dev environment restore =="
echo "PREFIX: $PREFIX"
echo "HOME:   $HOME_DIR"
echo "LONG:   $LONG"

# 1. Selectively restore missing Android/Java toolchain pieces.
TOOLCHAIN_TAR="$LONG/tools/android-toolchain.tar"
if [ -f "$TOOLCHAIN_TAR" ]; then
  if [ ! -x "$JDK/java" ] || [ ! -x "$JDK/javac" ]; then
    echo "-- restoring JDK from $TOOLCHAIN_TAR"
    "$TAR" -xf "$TOOLCHAIN_TAR" -C "$PREFIX" lib/jvm/java-21-openjdk
  fi
  if [ ! -x "$PREFIX/bin/aapt" ]; then
    echo "-- restoring aapt from $TOOLCHAIN_TAR"
    "$TAR" -xf "$TOOLCHAIN_TAR" -C "$PREFIX" bin/aapt
  fi
  if [ ! -f "$PREFIX/share/java/d8.jar" ]; then
    echo "-- restoring d8.jar from $TOOLCHAIN_TAR"
    "$TAR" -xf "$TOOLCHAIN_TAR" -C "$PREFIX" share/java/d8.jar
  fi
  if [ ! -f "$PREFIX/share/java/apksigner.jar" ]; then
    echo "-- restoring apksigner.jar from $TOOLCHAIN_TAR"
    "$TAR" -xf "$TOOLCHAIN_TAR" -C "$PREFIX" share/java/apksigner.jar
  fi
fi

# 2. Recreate launchers/symlinks if missing.
mkdir -p "$PREFIX/bin"
for t in java javac jar jarsigner keytool; do
  if [ ! -x "$PREFIX/bin/$t" ]; then
    ln -sfn "$JDK/$t" "$PREFIX/bin/$t"
    echo "-- recreated $t symlink"
  fi
done
if [ ! -e "$PREFIX/bin/d8" ]; then
  cat > "$PREFIX/bin/d8" <<LAUNCHER_D8
#!/system/bin/sh
exec $PREFIX/bin/java -cp $PREFIX/share/java/d8.jar com.android.tools.r8.D8 "\$@"
LAUNCHER_D8
  chmod 700 "$PREFIX/bin/d8"
  echo "-- recreated d8 launcher"
fi
if [ ! -e "$PREFIX/bin/r8" ]; then
  cat > "$PREFIX/bin/r8" <<LAUNCHER_R8
#!/system/bin/sh
exec $PREFIX/bin/java -cp $PREFIX/share/java/d8.jar com.android.tools.r8.R8 "\$@"
LAUNCHER_R8
  chmod 700 "$PREFIX/bin/r8"
  echo "-- recreated r8 launcher"
fi
if [ ! -e "$PREFIX/bin/apksigner" ]; then
  cat > "$PREFIX/bin/apksigner" <<LAUNCHER_APKSIGNER
#!/system/bin/sh
exec $PREFIX/bin/java -jar $PREFIX/share/java/apksigner.jar "\$@"
LAUNCHER_APKSIGNER
  chmod 700 "$PREFIX/bin/apksigner"
  echo "-- recreated apksigner launcher"
fi

# 2b. Restore Python 3.14 toolchain from archived Termux debs (missing files only).
PY_DEBS="$LONG/tools/python-debs"
if [ ! -x "$PREFIX/bin/python3.14" ]; then
  if [ -d "$PY_DEBS" ] && [ -x "$PREFIX/bin/dpkg-deb" ]; then
    echo "-- restoring Python 3.14 from $PY_DEBS"
    PY_STAGE="$PREFIX/tmp/python-restore-stage"
    rm -rf "$PY_STAGE"
    mkdir -p "$PY_STAGE"
    for d in "$PY_DEBS"/*.deb; do
      [ -f "$d" ] || continue
      "$PREFIX/bin/dpkg-deb" -x "$d" "$PY_STAGE" 2>/dev/null
    done
    PY_SRC="$PY_STAGE/data/data/com.termux/files/usr"
    rm -f "$PREFIX/tmp/python-restore-copied.lst"
    if [ -d "$PY_SRC" ]; then
      (cd "$PY_SRC" && /system/bin/find . -mindepth 1 -type f) 2>/dev/null | while IFS= read -r f; do
        case "$f" in
          ./share/man/*|./share/doc/*|./share/info/*|./lib/cmake/*|./lib/liblzma.so.5.8.3) continue ;;
        esac
        dst="$PREFIX/$f"
        if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
          mkdir -p "$(dirname "$dst")"
          cp -p "$PY_SRC/$f" "$dst"
          echo "$f" >> "$PREFIX/tmp/python-restore-copied.lst"
        fi
      done
      (cd "$PY_SRC" && /system/bin/find . -mindepth 1 -type l) 2>/dev/null | while IFS= read -r f; do
        dst="$PREFIX/$f"
        if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
          mkdir -p "$(dirname "$dst")"
          ln -s "$(/system/bin/readlink "$PY_SRC/$f")" "$dst"
          echo "$f" >> "$PREFIX/tmp/python-restore-copied.lst"
        fi
      done
    fi
    rm -rf "$PY_STAGE"
    if [ -f "$PREFIX/tmp/python-restore-copied.lst" ]; then
      echo "-- python restore copied $(wc -l < "$PREFIX/tmp/python-restore-copied.lst") missing files"
      rm -f "$PREFIX/tmp/python-restore-copied.lst"
    else
      echo "WARN: python archive extracted no usable files"
    fi
  else
    echo "WARN: python3.14 missing and no archive at $PY_DEBS (or dpkg-deb absent)"
  fi
fi
# Regenerate the python CA-bundle adaptation when missing (part of the python install).
PY_SC="$PREFIX/lib/python3.14/site-packages/sitecustomize.py"
if [ -d "$(dirname "$PY_SC")" ] && [ ! -f "$PY_SC" ]; then
  cat > "$PY_SC" <<'PY_SC_EOF'
# Python-on-DSH/Termux adaptation: CPython built for Termux compiles the
# default CA bundle path as the build-time prefix, which differs from the
# prefix this interpreter actually runs from. Point SSL at this prefix's
# CA bundle when the environment does not already provide one.
import os, sys
_cafile = os.path.join(sys.base_prefix, "etc", "tls", "cert.pem")
if os.path.isfile(_cafile):
    os.environ.setdefault("SSL_CERT_FILE", _cafile)
PY_SC_EOF
  chmod 600 "$PY_SC"
  echo "-- recreated python sitecustomize.py (CA bundle fix)"
fi

# 3. Repair termux-era paths in launcher scripts only (small, safe scope).
fix_text_file() {
  _f="$1"
  if /system/bin/grep -qI "$OLD" "$_f"; then
    /system/bin/sed -i "s@$OLD@$NEW@g" "$_f"
  fi
}
if [ -d "$PREFIX/bin" ]; then
  echo "-- repairing launchers in $PREFIX/bin"
  for f in "$PREFIX"/bin/*; do
    [ -f "$f" ] || continue
    fix_text_file "$f"
  done
fi
if [ -d "$PREFIX/libexec" ]; then
  echo "-- repairing launchers in $PREFIX/libexec"
  /system/bin/find "$PREFIX/libexec" -type f 2>/dev/null | while read -r f; do fix_text_file "$f"; done
fi
for dir in "$PREFIX/lib/node_modules/npm" "$PREFIX/lib/node_modules/corepack"; do
  if [ -d "$dir" ]; then
    echo "-- repairing Node launchers in $dir"
    /system/bin/find "$dir" -type f -name '*.js' 2>/dev/null | while read -r f; do fix_text_file "$f"; done
  fi
done

# 4. Recreate pnpm shims (dsh plugin needs pnpm on PATH).
if [ -x "$PREFIX/bin/corepack" ]; then
  echo "-- recreating pnpm/pnpx shims"
  "$PREFIX/bin/corepack" enable --install-directory "$PREFIX/bin" pnpm 2>/dev/null
  [ -L "$PREFIX/bin/pnpm" ] || ln -sfn ../lib/node_modules/corepack/dist/pnpm.js "$PREFIX/bin/pnpm"
  [ -L "$PREFIX/bin/pnpx" ] || ln -sfn ../lib/node_modules/corepack/dist/pnpx.js "$PREFIX/bin/pnpx"
fi

# 5. Restore home workspace from newest shared backup if the whole workspace is missing.
LATEST_HOME_TAR=$(/system/bin/ls -1t "$LONG"/backups/home/home-*.tar.gz 2>/dev/null | /system/bin/head -1)
if [ ! -d "$HOME_DIR/workspace" ] && [ -n "$LATEST_HOME_TAR" ]; then
  echo "-- restoring home workspace from $LATEST_HOME_TAR"
  mkdir -p "$HOME_DIR"
  "$GZIP" -dc "$LATEST_HOME_TAR" | "$TAR" -xf - -C "$HOME_DIR"
fi

# 6. Ensure JpgToPng project exists as a real directory in home (not a symlink).
mkdir -p "$HOME_DIR/workspace"
if [ -d "$LONG/export/JpgToPng" ]; then
  if [ -L "$HOME_DIR/workspace/JpgToPng" ]; then
    rm -f "$HOME_DIR/workspace/JpgToPng"
  fi
  if [ ! -e "$HOME_DIR/workspace/JpgToPng" ]; then
    echo "-- restoring JpgToPng project from shared export snapshot"
    (cd "$LONG/export" && "$TAR" -cf - JpgToPng) | (cd "$HOME_DIR/workspace" && "$TAR" -xf -)
  fi
fi

# 7. Restore missing DSH user long-term content from the shared backup.
BASE="$LONG/backups/dsh-profile"
restore_file_if_missing() {
  _src="$1"
  _dst="$2"
  if [ -f "$_src" ] && [ ! -f "$_dst" ]; then
    mkdir -p "$(dirname "$_dst")"
    cp -a "$_src" "$_dst"
    echo "-- restored missing: $_dst"
  fi
}
restore_dir_if_missing() {
  _src="$1"
  _dst="$2"
  if [ -d "$_src" ] && [ ! -d "$_dst" ]; then
    mkdir -p "$(dirname "$_dst")"
    cp -a "$_src" "$_dst"
    echo "-- restored missing: $_dst"
  fi
}

restore_file_if_missing "$BASE/settings.yaml" "$HOME_DIR/.dsh/settings.yaml"
restore_file_if_missing "$BASE/cordis.patch.yml" "$HOME_DIR/.dsh/cordis.patch.yml"
restore_file_if_missing "$BASE/AGENTS.md" "$HOME_DIR/.dsh/AGENTS.md"
restore_dir_if_missing "$BASE/skills" "$HOME_DIR/.dsh/skills"
restore_dir_if_missing "$BASE/.agent-presets" "$HOME_DIR/.dsh/.agent-presets"
restore_dir_if_missing "$BASE/agents-skills" "$HOME_DIR/.agents/skills"

# Restore secret-bearing files only when the user explicitly backed them up
# with --with-credentials. Keep them owner-only.
restore_file_if_missing "$BASE/.credentials.yaml" "$HOME_DIR/.dsh/.credentials.yaml"
restore_file_if_missing "$BASE/.env" "$HOME_DIR/.dsh/.env"
chmod 600 "$HOME_DIR/.dsh/.credentials.yaml" 2>/dev/null
chmod 600 "$HOME_DIR/.dsh/.env" 2>/dev/null

for p in "$BASE"/profiles/*; do
  [ -d "$p" ] || continue
  name="${p##*/}"
  pdst="$HOME_DIR/.dsh/profiles/$name"
  mkdir -p "$pdst"
  for f in package.json cordis.patch.yml pnpm-workspace.yaml pnpm-lock.yaml; do
    restore_file_if_missing "$p/$f" "$pdst/$f"
  done
  if [ -d "$p/android-packages" ] && [ ! -d "$pdst/node_modules/@dsh-android" ]; then
    mkdir -p "$pdst/node_modules"
    cp -a "$p/android-packages" "$pdst/node_modules/@dsh-android"
    echo "-- restored missing: $pdst/node_modules/@dsh-android"
  fi
done

# 8. Recreate Mobile compatibility items (Termux-on-DSH specifics).
mkdir -p "$PREFIX/bin"
for h in git-remote-http git-remote-https git-remote-ftp git-remote-ftps; do
  if [ ! -e "$PREFIX/bin/$h" ]; then
    ln -sfn ../libexec/git-core/git-remote-http "$PREFIX/bin/$h"
    echo "-- recreated $h symlink"
  fi
done

# @vscode/ripgrep ships no android platform build; this fabricated package
# makes grep/glob resolve to the Termux-built rg binary.
RG_PKG_DIR="$PREFIX/lib/node_modules/@deepseek-ai/dsh/node_modules/@vscode/ripgrep-android-arm64"
if [ ! -x "$RG_PKG_DIR/bin/rg" ]; then
  if [ -f "$LONG/tools/rg-15.2.0-arm64" ]; then
    mkdir -p "$RG_PKG_DIR/bin"
    cat > "$RG_PKG_DIR/package.json" <<'RG_PKG_JSON'
{"name":"@vscode/ripgrep-android-arm64","version":"1.18.0","private":true,"description":"Android/Termux-compatible ripgrep binary for @vscode/ripgrep resolution on Android"}
RG_PKG_JSON
    cp "$LONG/tools/rg-15.2.0-arm64" "$RG_PKG_DIR/bin/rg"
    chmod 755 "$RG_PKG_DIR/bin/rg"
    echo "-- recreated rg platform package"
  else
    echo "WARN: rg source binary missing: $LONG/tools/rg-15.2.0-arm64"
  fi
fi

# Home-level tool configs (CA bundle references + npm global prefix).
restore_file_if_missing "$BASE/home-config/gitconfig" "$HOME_DIR/.gitconfig"
restore_file_if_missing "$BASE/home-config/curlrc" "$HOME_DIR/.curlrc"
restore_file_if_missing "$BASE/home-config/wgetrc" "$HOME_DIR/.wgetrc"
restore_file_if_missing "$BASE/home-config/npmrc" "$HOME_DIR/.npmrc"
chmod 600 "$HOME_DIR/.gitconfig" "$HOME_DIR/.curlrc" "$HOME_DIR/.wgetrc" "$HOME_DIR/.npmrc" 2>/dev/null
CERT="$PREFIX/etc/tls/cert.pem"
if [ ! -f "$CERT" ]; then
  echo "WARN: CA bundle missing: $CERT (git/curl/wget configs reference it)"
fi

# 9. Quick verification.
echo "-- verification"
for t in bash git node npm corepack pnpm java javac aapt d8 r8 apksigner make curl python3 pip3; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "OK: $t ($(command -v "$t"))"
  else
    echo "MISSING: $t"
  fi
done
if command -v python3 >/dev/null 2>&1; then
  if python3 -c "import ssl, sqlite3, sys; ssl.get_default_verify_paths(); assert sys.base_prefix.startswith('/data')" >/dev/null 2>&1; then
    echo "OK: python3 stdlib (ssl, sqlite3, base_prefix)"
  else
    echo "CHECK: python3 stdlib import failed"
  fi
fi
if [ -d "$HOME_DIR/workspace/JpgToPng" ] && [ ! -L "$HOME_DIR/workspace/JpgToPng" ]; then
  echo "OK: workspace/JpgToPng (real directory in files/home)"
else
  echo "CHECK: workspace/JpgToPng missing or not a real directory"
fi
if [ -x "$PREFIX/lib/node_modules/@deepseek-ai/dsh/node_modules/@vscode/ripgrep-android-arm64/bin/rg" ]; then
  echo "OK: rg platform package (grep/glob)"
else
  echo "CHECK: rg platform package missing"
fi
for h in git-remote-http git-remote-https; do
  if [ -e "$PREFIX/bin/$h" ]; then echo "OK: $h helper"; else echo "MISSING: $h helper"; fi
done
for f in .gitconfig .curlrc .wgetrc .npmrc; do
  if [ -f "$HOME_DIR/$f" ]; then echo "OK: $f"; else echo "MISSING: $f"; fi
done
echo "== done =="
