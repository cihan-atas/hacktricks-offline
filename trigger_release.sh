#!/usr/bin/env bash
# ==============================================================================
# HackTricks Vault - Manuel Release & Build Tetikleyici
# ==============================================================================
# Kullanım:
#   ./trigger_release.sh          -> GitHub Actions üzerinde derleme başlatır
#   ./trigger_release.sh --local  -> Yerel makinede derleyip GitHub'a yükler
# ==============================================================================

set -e

# Renkler
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}   🛡️  HackTricks Vault — Release Tetikleyici         ${NC}"
echo -e "${CYAN}======================================================${NC}"

MODE="${1:-github}"

if [ "$MODE" == "--local" ] || [ "$MODE" == "local" ]; then
    echo -e "${BLUE}[*] Yerel Derleme ve Release Modu Seçildi.${NC}"
    echo -e "${YELLOW}[1/4] Upstream kaynaklar taranıyor ve veriler derleniyor...${NC}"
    python3 scripts/build_hacktricks_content.py
    python3 scripts/extract_hacktricks_commands.py
    python3 scripts/generate_release_notes.py

    echo -e "\n${YELLOW}[2/4] Flutter Android Release APK derleniyor...${NC}"
    cd app
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH
    flutter pub get
    flutter build apk --release --no-tree-shake-icons
    cd "$PROJECT_ROOT"

    mkdir -p dist
    cp app/build/app/outputs/flutter-apk/app-release.apk dist/HackTricks_Vault.apk

    echo -e "\n${YELLOW}[3/4] GitHub Release güncelleniyor...${NC}"
    LATEST_TAG=$(gh release list --limit 1 --json tagName -q '.[0].tagName')
    if [ -n "$LATEST_TAG" ]; then
        echo -e "${GREEN}✓ Mevcut sürüm ($LATEST_TAG) güncelleniyor...${NC}"
        gh release upload "$LATEST_TAG" dist/HackTricks_Vault.apk --clobber
        gh release edit "$LATEST_TAG" --notes-file RELEASE_NOTES.md
    else
        echo -e "${GREEN}✓ Yeni sürüm (v2.0.1) oluşturuluyor...${NC}"
        gh release create v2.0.1 dist/HackTricks_Vault.apk --title "HackTricks Vault v2.0.1" --notes-file RELEASE_NOTES.md
    fi

    echo -e "\n${GREEN}🎉 [✓] Yerel derleme ve Release güncellemesi tamamlandı!${NC}"
    exit 0
fi

# Varsayılan: GitHub Actions Üzerinde Manuel Tetikleme
echo -e "${BLUE}[*] GitHub Actions üzerinde bulut derlemesi tetikleniyor...${NC}"

if ! command -v gh &> /dev/null; then
    echo -e "${RED}[!] 'gh' (GitHub CLI) bulunamadı! Lütfen kurun veya './trigger_release.sh --local' kullanın.${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/2] 'Build HackTricks Vault APK' workflow'u başlatılıyor...${NC}"
gh workflow run build-apk.yml --ref main

echo -e "${GREEN}✓ Workflow başarıyla tetiklendi!${NC}"
echo -e "${YELLOW}[2/2] Canlı çalıştırma durumu kontrol ediliyor...${NC}"
sleep 3

# Son başlatılan çalıştırmayı göster
gh run list --workflow=build-apk.yml --limit 1

echo -e "\n${CYAN}------------------------------------------------------${NC}"
echo -e "${GREEN}İşlem arka planda GitHub sunucularında başladı.${NC}"
echo -e "Canlı logları takip etmek için şu komutu çalıştırabilirsiniz:"
echo -e "${YELLOW}  gh run watch${NC}"
echo -e "Veya tarayıcıdan izlemek için:"
echo -e "${YELLOW}  https://github.com/cihan-atas/hacktricks-offline/actions${NC}"
echo -e "${CYAN}------------------------------------------------------${NC}"
