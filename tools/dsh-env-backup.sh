#!/system/bin/sh
# Back up user-owned DSH long-term content to shared storage:
#   settings, home-level patch, user-global AGENTS.md, skills, agent presets,
#   ~/.agents/skills, and every profile's user-owned files (package.json /
#   cordis.patch.yml / pnpm workspace+lockfile) plus untracked @dsh-android
#   adaptation packages.
#
# Usage:
#   sh /storage/emulated/0/DSH/tools/dsh-env-backup.sh
#   sh /storage/emulated/0/DSH/tools/dsh-env-backup.sh --with-credentials
#
# The secret-bearing files .credentials.yaml and .env are only included with
# --with-credentials.
HOME_DIR="${HOME:-/data/user/0/com.dshmobile.shell/files/home}"
LONG="/storage/emulated/0/DSH"
SRC="$HOME_DIR/.dsh"
DST="$LONG/backups/dsh-profile"

echo "== DSH user content backup =="
echo "SRC: $SRC"
echo "DST: $DST"
mkdir -p "$DST/profiles"
# Keep Android's media scanner out of the backup tree: *.ts / *.d.ts files
# under here (type declarations of the client UI packages) would otherwise be
# misclassified as MPEG-TS videos and flood the gallery with 0-second clips.
touch "$LONG/backups/.nomedia"

backup_file() {
  _name="$1"
  _src="$2"
  _dst="$3"
  if [ -f "$_src" ]; then
    mkdir -p "$(dirname "$_dst")"
    cp -a "$_src" "$_dst"
    echo "backed up: $_name"
  else
    echo "missing, skipped: $_name" >&2
  fi
}
backup_optional_file() {
  _name="$1"
  _src="$2"
  _dst="$3"
  if [ -f "$_src" ]; then
    mkdir -p "$(dirname "$_dst")"
    cp -a "$_src" "$_dst"
    echo "backed up: $_name"
  fi
}
backup_dir() {
  _name="$1"
  _src="$2"
  _dst="$3"
  if [ -d "$_src" ]; then
    mkdir -p "$(dirname "$_dst")"
    rm -rf "$_dst"
    cp -a "$_src" "$_dst"
    echo "backed up: $_name"
  fi
}

backup_file "settings.yaml" "$SRC/settings.yaml" "$DST/settings.yaml"
backup_optional_file "cordis.patch.yml (home-level)" "$SRC/cordis.patch.yml" "$DST/cordis.patch.yml"
backup_optional_file "AGENTS.md (user-global)" "$SRC/AGENTS.md" "$DST/AGENTS.md"
backup_dir "skills" "$SRC/skills" "$DST/skills"
backup_dir ".agent-presets" "$SRC/.agent-presets" "$DST/.agent-presets"
backup_dir "~/.agents/skills" "$HOME_DIR/.agents/skills" "$DST/agents-skills"

for p in "$SRC"/profiles/*; do
  [ -d "$p" ] || continue
  name="${p##*/}"
  [ "$name" = "node_modules" ] && continue
  pdst="$DST/profiles/$name"
  echo "-- profile: $name"
  for f in package.json cordis.patch.yml pnpm-workspace.yaml pnpm-lock.yaml; do
    backup_optional_file "profiles/$name/$f" "$p/$f" "$pdst/$f"
  done
  if [ -d "$p/node_modules/@dsh-android" ]; then
    backup_dir "profiles/$name/node_modules/@dsh-android" "$p/node_modules/@dsh-android" "$pdst/android-packages"
  fi
done

# Home-level tool configs created by the Mobile compatibility setup.
backup_optional_file "home-config/gitconfig" "$HOME_DIR/.gitconfig" "$DST/home-config/gitconfig"
backup_optional_file "home-config/curlrc" "$HOME_DIR/.curlrc" "$DST/home-config/curlrc"
backup_optional_file "home-config/wgetrc" "$HOME_DIR/.wgetrc" "$DST/home-config/wgetrc"
backup_optional_file "home-config/npmrc" "$HOME_DIR/.npmrc" "$DST/home-config/npmrc"

if [ "$1" = "--with-credentials" ]; then
  backup_optional_file ".credentials.yaml" "$SRC/.credentials.yaml" "$DST/.credentials.yaml"
  backup_optional_file ".env" "$SRC/.env" "$DST/.env"
  chmod 600 "$DST/.credentials.yaml" 2>/dev/null
  chmod 600 "$DST/.env" 2>/dev/null
  echo "credentials/env backed up; keep these files private"
else
  echo "credentials/.env skipped; use --with-credentials to include them"
fi

echo "== done =="
