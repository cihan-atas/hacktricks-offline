#!/usr/bin/env bash
# ==============================================================================
# HackTricks Vault - Evrensel Derleme Betiği (APK & Web)
# ==============================================================================
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$PROJECT_DIR/app"
DIST_DIR="$PROJECT_DIR/dist"

MODE="${1:---apk}"

echo "================================================================="
echo "  🛡️  HACKTRICKS VAULT - DERLEME SİSTEMİ"
echo "================================================================="

if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
elif [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
fi

export PATH="$JAVA_HOME/bin:/home/zeus/development/flutter/bin:$PATH"
export ANDROID_HOME="/home/zeus/Android/Sdk"

echo "[1/3] 🔍 Ortam Kontrol Ediliyor..."
echo "  • Flutter: $(flutter --version | head -n 1)"

echo ""
echo "[2/3] 📚 HackTricks Dokümanları Taranıyor (TR & EN)..."
mkdir -p "$PROJECT_DIR/sources"
if [ ! -d "$PROJECT_DIR/sources/hacktricks-en/.git" ]; then
    git clone --depth 1 --branch master https://github.com/HackTricks-wiki/hacktricks.git "$PROJECT_DIR/sources/hacktricks-en"
fi
if [ ! -d "$PROJECT_DIR/sources/hacktricks-tr/.git" ]; then
    git clone --depth 1 --branch tr https://github.com/HackTricks-wiki/hacktricks.git "$PROJECT_DIR/sources/hacktricks-tr"
fi
if [ ! -d "$PROJECT_DIR/sources/hacktricks-cloud/.git" ]; then
    git clone --depth 1 --branch master https://github.com/HackTricks-wiki/hacktricks-cloud.git "$PROJECT_DIR/sources/hacktricks-cloud"
fi
if [ ! -d "$PROJECT_DIR/sources/hacktricks-cloud-tr/.git" ]; then
    git clone --depth 1 --branch tr https://github.com/HackTricks-wiki/hacktricks-cloud.git "$PROJECT_DIR/sources/hacktricks-cloud-tr"
fi

python3 "$PROJECT_DIR/scripts/build_hacktricks_content.py"
python3 "$PROJECT_DIR/scripts/extract_hacktricks_commands.py"

mkdir -p "$DIST_DIR"
cd "$APP_DIR"

if [ "$MODE" == "--apk" ] || [ "$MODE" == "--all" ]; then
    echo ""
    echo "[3/3] ⚙️  Android APK Derleniyor (Release)..."
    flutter build apk --release --no-tree-shake-icons
    cp "$APP_DIR/build/app/outputs/flutter-apk/app-release.apk" "$DIST_DIR/HackTricks_Vault.apk"
    echo "  ✓ APK Hazır: $DIST_DIR/HackTricks_Vault.apk ($(du -h "$DIST_DIR/HackTricks_Vault.apk" | cut -f1))"
fi

if [ "$MODE" == "--web" ] || [ "$MODE" == "--all" ]; then
    echo ""
    echo "[3/3] 🌐 Web Sürümü Derleniyor (Release)..."
    flutter build web --release
    mkdir -p "$DIST_DIR/web"
    cp -r "$APP_DIR/build/web/"* "$DIST_DIR/web/"
    echo "  ✓ Web Sürümü Hazır: $DIST_DIR/web/"
fi

echo ""
echo "================================================================="
echo "  ✅ İŞLEM BAŞARIYLA TAMAMLANDI!"
echo "================================================================="
if [ -f "$DIST_DIR/HackTricks_Vault.apk" ]; then
    echo "  📱 APK: adb install -r $DIST_DIR/HackTricks_Vault.apk"
fi
if [ -d "$DIST_DIR/web" ]; then
    echo "  🌐 Web: python3 -m http.server -d dist/web 8080"
fi
echo "================================================================="
