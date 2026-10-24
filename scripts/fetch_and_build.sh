#!/usr/bin/env bash
set -e

# Renkler
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$PROJECT_ROOT/bin"
SOURCES_DIR="$PROJECT_ROOT/sources"
ASSETS_DIR="$PROJECT_ROOT/android/app/src/main/assets/www"

export PATH="$BIN_DIR:$PATH"

echo -e "${BLUE}=== HackTricks Offline Builder Başlatılıyor ===${NC}"
echo "Proje dizini: $PROJECT_ROOT"

# mdbook kontrolü
if ! command -v mdbook &> /dev/null; then
    echo -e "${YELLOW}mdbook bulunamadı, indiriliyor...${NC}"
    mkdir -p "$BIN_DIR"
    curl -sL https://github.com/rust-lang/mdBook/releases/download/v0.5.4/mdbook-v0.5.4-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C "$BIN_DIR"
fi

mkdir -p "$SOURCES_DIR"
mkdir -p "$ASSETS_DIR"

# 1. İngilizce Dokümanları Çek ve Derle
echo -e "\n${BLUE}[1/3] İngilizce (EN) dokümanlar hazırlanıyor...${NC}"
EN_DIR="$SOURCES_DIR/hacktricks-en"
if [ ! -d "$EN_DIR/.git" ]; then
    echo "Cloning HackTricks (master branch, depth 1)..."
    git clone --depth 1 --branch master https://github.com/HackTricks-wiki/hacktricks.git "$EN_DIR"
else
    echo "Mevcut repo güncelleniyor (master branch)..."
    cd "$EN_DIR"
    git fetch --depth 1 origin master
    git reset --hard origin/master
fi

echo "İngilizce dokümantasyon mdBook ile derleniyor..."
cd "$EN_DIR"
MDBOOK_PREPROCESSOR__HACKTRICKS__ENV=dev mdbook build
echo -e "${GREEN}✓ İngilizce dokümanlar başarıyla derlendi.${NC}"

# 2. Türkçe Dokümanları Çek ve Derle
echo -e "\n${BLUE}[2/3] Türkçe (TR) dokümanlar hazırlanıyor...${NC}"
TR_DIR="$SOURCES_DIR/hacktricks-tr"
if [ ! -d "$TR_DIR/.git" ]; then
    echo "Cloning HackTricks (tr branch, depth 1)..."
    git clone --depth 1 --branch tr https://github.com/HackTricks-wiki/hacktricks.git "$TR_DIR"
else
    echo "Mevcut repo güncelleniyor (tr branch)..."
    cd "$TR_DIR"
    git fetch --depth 1 origin tr
    git reset --hard origin/tr
fi

echo "Türkçe dokümantasyon mdBook ile derleniyor..."
cd "$TR_DIR"
MDBOOK_PREPROCESSOR__HACKTRICKS__ENV=dev mdbook build
echo -e "${GREEN}✓ Türkçe dokümanlar başarıyla derlendi.${NC}"

# 3. Android Assets Dizinine Dosyaları Taşıma
echo -e "\n${BLUE}[3/3] Android www/ dizinine kopyalanıyor...${NC}"
rm -rf "$ASSETS_DIR/en" "$ASSETS_DIR/tr"
mkdir -p "$ASSETS_DIR/en" "$ASSETS_DIR/tr"

cp -r "$EN_DIR/book/"* "$ASSETS_DIR/en/"
cp -r "$TR_DIR/book/"* "$ASSETS_DIR/tr/"

# Ana Açılış Portalı (index.html)
cat << 'EOF' > "$ASSETS_DIR/index.html"
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>HackTricks Offline</title>
    <style>
        :root {
            --bg-color: #0d1117;
            --card-bg: #161b22;
            --border-color: #30363d;
            --text-color: #c9d1d9;
            --text-dim: #8b949e;
            --accent-color: #58a6ff;
            --accent-hover: #1f6feb;
            --green: #2ea043;
        }
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            -webkit-tap-highlight-color: transparent;
        }
        body {
            background-color: var(--bg-color);
            color: var(--text-color);
            display: flex;
            flex-direction: column;
            min-height: 100vh;
            padding: 24px 16px;
        }
        .header {
            text-align: center;
            margin-top: 20px;
            margin-bottom: 30px;
        }
        .logo-box {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 72px;
            height: 72px;
            background: linear-gradient(135deg, #1f6feb, #238636);
            border-radius: 18px;
            margin-bottom: 16px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.4);
        }
        .logo-box svg {
            width: 40px;
            height: 40px;
            fill: white;
        }
        h1 {
            font-size: 26px;
            font-weight: 700;
            letter-spacing: -0.5px;
            margin-bottom: 6px;
            color: #ffffff;
        }
        .subtitle {
            font-size: 14px;
            color: var(--text-dim);
        }
        .badge {
            display: inline-block;
            background: rgba(46, 160, 67, 0.15);
            color: #3fb950;
            border: 1px solid rgba(46, 160, 67, 0.4);
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            margin-top: 10px;
        }
        .container {
            max-width: 500px;
            width: 100%;
            margin: 0 auto;
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 16px;
        }
        .lang-card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 14px;
            padding: 20px;
            display: flex;
            align-items: center;
            text-decoration: none;
            color: inherit;
            transition: transform 0.15s ease, border-color 0.15s ease, background-color 0.15s ease;
        }
        .lang-card:active {
            transform: scale(0.98);
            background-color: #21262d;
            border-color: var(--accent-color);
        }
        .lang-icon {
            font-size: 32px;
            margin-right: 18px;
            display: flex;
            align-items: center;
            justify-content: center;
            width: 48px;
            height: 48px;
            background: rgba(255,255,255,0.05);
            border-radius: 12px;
        }
        .lang-info {
            flex: 1;
        }
        .lang-title {
            font-size: 18px;
            font-weight: 600;
            color: #ffffff;
            margin-bottom: 4px;
        }
        .lang-desc {
            font-size: 13px;
            color: var(--text-dim);
            line-height: 1.4;
        }
        .lang-arrow {
            font-size: 20px;
            color: var(--text-dim);
            margin-left: 10px;
        }
        .tips-box {
            background: rgba(88, 166, 255, 0.05);
            border: 1px solid rgba(88, 166, 255, 0.2);
            border-radius: 12px;
            padding: 16px;
            margin-top: 12px;
        }
        .tips-title {
            font-size: 13px;
            font-weight: 600;
            color: var(--accent-color);
            margin-bottom: 6px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .tips-content {
            font-size: 12px;
            color: var(--text-dim);
            line-height: 1.5;
        }
        .footer {
            margin-top: auto;
            padding-top: 24px;
            text-align: center;
            font-size: 11px;
            color: #484f58;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo-box">
            <svg viewBox="0 0 24 24">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
            </svg>
        </div>
        <h1>HackTricks Offline</h1>
        <p class="subtitle">Pentest & Security Knowledge Base</p>
        <span class="badge">100% Çevrimdışı (Offline)</span>
    </div>

    <div class="container">
        <a href="./tr/index.html" class="lang-card">
            <div class="lang-icon">🇹🇷</div>
            <div class="lang-info">
                <div class="lang-title">Türkçe Dokümanlar</div>
                <div class="lang-desc">Türkçe çeviri arşivi ve pentesting rehberleri</div>
            </div>
            <div class="lang-arrow">›</div>
        </a>

        <a href="./en/index.html" class="lang-card">
            <div class="lang-icon">🇬🇧</div>
            <div class="lang-info">
                <div class="lang-title">English Documentation</div>
                <div class="lang-desc">Full & latest original database (master branch)</div>
            </div>
            <div class="lang-arrow">›</div>
        </a>

        <div class="tips-box">
            <div class="tips-title">💡 İpucu</div>
            <div class="tips-content">
                İçerik sayfalarında sol üstteki arama ikonunu kullanarak tüm dokümanlarda internetsiz anlık arama yapabilirsiniz.
            </div>
        </div>
    </div>

    <div class="footer">
        Powered by HackTricks Community & mdBook
    </div>
</body>
</html>
EOF

echo -e "\n${GREEN}============================================${NC}"
echo -e "${GREEN}✓ Tüm dokümanlar derlendi ve hazırlandı!${NC}"
echo -e "${GREEN}============================================${NC}"
