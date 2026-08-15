#!/system/bin/sh
# JpgToPng APK build script (no Android SDK): aapt + javac + d8 + zipalign + apksigner.
# Verified on the DSH Mobile runtime (Termux-style prefix, aarch64).
#
# Signing: if app/build/jpgtopng.keystore does not exist, a local dev keystore is
# generated with a random password (printed once) or the password given via
# JPGTOPNG_KS_PASS. This file intentionally contains NO stored password.
set -e

PREFIX="${TERMUX__PREFIX:-/data/user/0/com.dshmobile.shell/files/usr}"
export JAVA_HOME="$PREFIX/lib/jvm/java-21-openjdk"
export PATH="$PREFIX/bin:$JAVA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

cd "$(dirname "$0")"
B=app/build
rm -rf "$B"
mkdir -p "$B/classes_stub" "$B/classes_app" "$B/dex"

# 1. compile the minimal android stub and jar it
javac -d "$B/classes_stub" $(find app/stub/src -name '*.java')
jar cf "$B/android-stub.jar" -C "$B/classes_stub" .

# 2. compile the app against the stub
javac -source 1.8 -target 1.8 -cp "$B/android-stub.jar" -d "$B/classes_app"   app/src/main/java/com/example/jpgtopng/MainActivity.java

# 3. dex the app classes
java -cp "$PREFIX/share/java/d8.jar" com.android.tools.r8.D8 --release --min-api 24   --output "$B/dex" "$B"/classes_app/com/example/jpgtopng/*.class

# 4. package resources + manifest; the device framework-res.apk supplies @android: entries
"$PREFIX/bin/aapt" package -f -M app/AndroidManifest.xml -S app/res   -I /system/framework/framework-res.apk -F "$B/JpgToPng.unsigned.apk"

# 5. add classes.dex into the apk
jar uf "$B/JpgToPng.unsigned.apk" -C "$B/dex" classes.dex

# 6. align
"$PREFIX/bin/zipalign" -f 4 "$B/JpgToPng.unsigned.apk" "$B/JpgToPng.aligned.apk"

# 7. local dev keystore (generated here, never committed)
KS="$B/jpgtopng.keystore"
if [ ! -f "$KS" ]; then
  KS_PASS="${JPGTOPNG_KS_PASS:-}"
  if [ -z "$KS_PASS" ]; then
    KS_PASS=$(cat /proc/sys/kernel/random/uuid)
  fi
  keytool -genkeypair -keystore "$KS" -alias jpgtopng -keyalg RSA -keysize 2048     -validity 10000 -storepass "$KS_PASS" -keypass "$KS_PASS" -dname "CN=JpgToPng"
  echo "generated dev keystore $KS (password printed below; keep it if you reuse this keystore)"
  echo "keystore password: $KS_PASS"
else
  KS_PASS="${JPGTOPNG_KS_PASS:?existing keystore found: set JPGTOPNG_KS_PASS to its password}"
fi

# 8. sign and verify
java -jar "$PREFIX/share/java/apksigner.jar" sign --ks "$KS" --ks-key-alias jpgtopng   --ks-pass "pass:$KS_PASS" --key-pass "pass:$KS_PASS"   --out "$B/JpgToPng.apk" "$B/JpgToPng.aligned.apk"
java -jar "$PREFIX/share/java/apksigner.jar" verify --verbose "$B/JpgToPng.apk" | tail -5

echo "== done =="
ls -l "$B/JpgToPng.apk"
