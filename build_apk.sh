#!/usr/bin/env bash
# ==============================================================================
# HackTricks Vault - Android APK Derleme Betiği
# ==============================================================================
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$PROJECT_DIR/app"
DIST_DIR="$PROJECT_DIR/dist"

echo "================================================================="
echo "  🛡️  HACKTRICKS VAULT - ANDROID DERLEME SİSTEMİ"
echo "================================================================="

if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
elif [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
fi

export PATH="$JAVA_HOME/bin:/home/zeus/development/flutter/bin:$PATH"
export ANDROID_HOME="/home/zeus/Android/Sdk"

echo "[1/3] 🔍 Ortam ve Çevre Kontrol Ediliyor..."
echo "  • JAVA_HOME: $JAVA_HOME"
echo "  • Flutter: $(flutter --version | head -n 1)"
echo "  • Android SDK: $ANDROID_HOME"

echo ""
echo "[2/3] 📚 HackTricks Dokümanları Taranıyor (TR & EN)..."
python3 "$PROJECT_DIR/scripts/build_hacktricks_content.py"

echo ""
echo "[3/3] ⚙️  Flutter Android APK Derleniyor (Release Modu)..."
cd "$APP_DIR"
flutter build apk --release --no-tree-shake-icons

mkdir -p "$DIST_DIR"
BUILT_APK="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
TARGET_APK="$DIST_DIR/HackTricks_Vault.apk"

if [ -f "$BUILT_APK" ]; then
    cp "$BUILT_APK" "$TARGET_APK"
    APK_SIZE=$(du -h "$TARGET_APK" | cut -f1)
    echo ""
    echo "================================================================="
    echo "  ✅ HACKTRICKS VAULT APK BAŞARIYLA DERLENDİ!"
    echo "================================================================="
    echo "  📱 APK Dosyası: $TARGET_APK"
    echo "  📦 Dosya Boyutu: $APK_SIZE"
    echo "  🌐 Diller: 🇹🇷 Türkçe & 🇬🇧 İngilizce"
    echo "  🔊 Ses Motoru: Gelişmiş Floating TTS & Spiker Profilleri"
    echo "  ✨ AI Asistan: Gemini / Groq / OpenRouter Destekli"
    echo "  📄 Konu Sayısı: 2.260+ Doküman"
    echo "================================================================="
    echo "Cihaza yüklemek için:"
    echo "  adb install -r $TARGET_APK"
    echo "================================================================="
else
    echo "❌ HATA: APK dosyası bulunamadı: $BUILT_APK"
    exit 1
fi
