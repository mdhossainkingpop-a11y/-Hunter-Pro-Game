#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ALIAS="worldlife3d"
KEYSTORE="world-life-3d-upload-key.jks"

echo "WORLD LIFE 3D - Play Store upload key generator"
echo "This key is generated locally on this phone."
echo "Do NOT upload the .jks file to GitHub or share it in chat."
echo

if [ -e "$KEYSTORE" ]; then
  echo "ERROR: $KEYSTORE already exists. Keep the existing key; do not overwrite it."
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool is missing. Install Java first: pkg update && pkg install openjdk-21"
  exit 1
fi

keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

echo
echo "Key created: $KEYSTORE"
echo "Alias: $ALIAS"
echo
echo "Keep TWO secure backups of the JKS file and remember the passwords."
echo "Now create the Base64 value for GitHub Secret ANDROID_KEYSTORE_BASE64."
echo "Copy the long line below into GitHub Secrets only; do not send it to anyone."
echo
base64 "$KEYSTORE" | tr -d '\n'
echo
echo
echo "Add these GitHub Actions repository secrets:"
echo "ANDROID_KEYSTORE_BASE64 = the Base64 line printed above"
echo "ANDROID_KEY_ALIAS = $ALIAS"
echo "ANDROID_KEYSTORE_PASSWORD = the password you entered in keytool"
echo
echo "Never commit the JKS file or Base64 value to the repository."
