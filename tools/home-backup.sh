#!/system/bin/sh
# Archive the personal files/home workspace to shared storage.
# The archive preserves Linux file semantics (tar) and is stored under:
#   /storage/emulated/0/DSH/backups/home/home-<timestamp>.tar.gz
#
# Restore manually with:
#   gzip -dc <archive> | tar -xf - -C ~
# Or run dsh-env-restore.sh; it restores the newest home archive only when
# ~/workspace is entirely missing.
PREFIX="${TERMUX__PREFIX:-/data/user/0/com.dshmobile.shell/files/usr}"
HOME_DIR="${HOME:-/data/user/0/com.dshmobile.shell/files/home}"
LONG="/storage/emulated/0/DSH"
STAMP=$(/system/bin/date +%Y%m%d-%H%M%S)
DST_DIR="$LONG/backups/home"
DST="$DST_DIR/home-$STAMP.tar.gz"
TAR="$PREFIX/bin/tar"
[ -x "$TAR" ] || TAR=/system/bin/tar
GZIP="$PREFIX/bin/gzip"
[ -x "$GZIP" ] || GZIP=/system/bin/gzip

echo "== home workspace backup =="
echo "SRC: $HOME_DIR/workspace"
echo "DST: $DST"

mkdir -p "$DST_DIR"
# Keep the media scanner out of the backups tree (see dsh-env-backup.sh).
touch "$LONG/backups/.nomedia"
"$TAR" -C "$HOME_DIR" -cf - \
  --exclude='node_modules' \
  workspace | "$GZIP" -c > "$DST"
ls -lh "$DST"
echo "== done =="
