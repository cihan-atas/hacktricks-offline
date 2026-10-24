#!/usr/bin/env python3
"""
HackTricks Vault - İçerik Çıkarıcı ve İndeksleyici
Bu betik:
- 'sources/hacktricks-en/src' ve 'sources/hacktricks-tr/src' dizinlerini tarar.
- SUMMARY.md hiyerarşisini parse eder.
- Markdown içeriklerini temizleyip optimize edilmiş JSON'lar olarak:
  app/assets/data/en/
  app/assets/data/tr/
  dizinlerine yazar.
"""

import os
import re
import json
import hashlib
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
EN_SRC = BASE_DIR / "sources" / "hacktricks-en" / "src"
TR_SRC = BASE_DIR / "sources" / "hacktricks-tr" / "src"
ASSETS_DIR = BASE_DIR / "app" / "assets" / "data"

PILLAR_COLORS = [
    "#ef4444", "#f97316", "#f59e0b", "#10b981", "#06b6d4",
    "#3b82f6", "#6366f1", "#8b5cf6", "#d946ef", "#ec4899",
    "#14b8a6", "#84cc16", "#eab308", "#a855f7", "#0284c7",
    "#38bdf8", "#4ade80", "#fb7185", "#f43f5e", "#64748b"
]

def clean_markdown(content: str) -> str:
    """GitBook / mdBook özel etiketlerini temizle ve Flutter Markdown için optimize et."""
    # {% hint style="..." %} bloklarını markdown alıntılarına çevir
    content = re.sub(r'\{%\s*hint\s+style="(\w+)"\s*%\}(.*?)\{%\s*endhint\s*%\}', r'> **[\1]** \2', content, flags=re.DOTALL)
    content = re.sub(r'\{%\s*hint[^\%]*%\}(.*?)\{%\s*endhint\s*%\}', r'> \1', content, flags=re.DOTALL)
    # Başıboş kalan hint etiketlerini temizle
    content = re.sub(r'\{%\s*(?:hint|endhint)[^\%]*%\}', '', content)
    # mdbook-tabs etiketlerini temizle
    content = re.sub(r'<!--\s*(?:tabs|endtabs)\s*-->', '', content)
    # Fazla boş satırları toparla
    content = re.sub(r'\n{3,}', '\n\n', content)
    return content.strip()

def extract_description(content: str, fallback_title: str) -> str:
    """Makaleden ilk paragrafı özet açıklama olarak çıkar."""
    lines = content.splitlines()
    for line in lines:
        line = line.strip()
        if not line:
            continue
        if line.startswith('#') or line.startswith('>') or line.startswith('```') or line.startswith('-') or line.startswith('*'):
            continue
        if len(line) > 20:
            clean = re.sub(r'\[(.*?)\]\(.*?\)', r'\1', line)
            clean = re.sub(r'[*_`]', '', clean)
            return clean[:180] + ('...' if len(clean) > 180 else '')
    return fallback_title

def parse_language(src_dir: Path, out_dir: Path, lang_code: str):
    summary_path = src_dir / "SUMMARY.md"
    if not summary_path.exists():
        print(f"[!] SUMMARY.md bulunamadı: {summary_path}")
        return

    print(f"[+] '{lang_code}' dili işleniyor ({src_dir})...")
    out_dir.mkdir(parents=True, exist_ok=True)

    with open(summary_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    pillars = []
    current_pillar = None
    articles_map = {}
    search_index = []
    color_idx = 0

    current_module = None

    for line in lines:
        raw = line.rstrip()
        stripped = raw.strip()
        if not stripped:
            continue

        if stripped.startswith('# '):
            pname = stripped[2:].strip()
            if pname.lower() == 'summary.md':
                continue
            pid = re.sub(r'[^a-zA-Z0-9]+', '_', pname).strip('_').lower()
            current_pillar = {
                'id': pid,
                'name': pname,
                'subtitle': f'{pname} dokümantasyon ve teknikleri',
                'dir': pid,
                'color': PILLAR_COLORS[color_idx % len(PILLAR_COLORS)],
                'featured_articles': [],
                'modules': []
            }
            color_idx += 1
            pillars.append(current_pillar)
            current_module = None
            continue

        # Markdown liste bağlantısı
        m = re.match(r'^(\s*)[-*]\s*\[(.*?)\]\((.*?)\)', raw)
        if m and current_pillar:
            indent = len(m.group(1))
            title = m.group(2).strip()
            link = m.group(3).split('#')[0].strip()

            if not link.endswith('.md'):
                continue

            md_path = src_dir / link
            content = ""
            desc = title
            if md_path.exists():
                try:
                    with open(md_path, 'r', encoding='utf-8', errors='ignore') as mf:
                        raw_content = mf.read()
                        content = clean_markdown(raw_content)
                        desc = extract_description(content, title)
                except Exception as e:
                    print(f"Hata ({link}): {e}")

            art_id = hashlib.md5(link.encode('utf-8')).hexdigest()[:12]

            art_summary = {
                'id': art_id,
                'title': title,
                'description': desc,
                'path': link,
                'is_readme': link.endswith('README.md')
            }

            # Hiyerarşik gruplama
            if indent == 0 or current_module is None:
                current_module = {
                    'id': art_id,
                    'folder': link.split('/')[0] if '/' in link else '',
                    'title': title,
                    'path': link,
                    'has_subcategories': False,
                    'subcategories': [],
                    'articles': [art_summary]
                }
                current_pillar['modules'].append(current_module)
            else:
                current_module['articles'].append(art_summary)

            # Makale Detayı
            articles_map[art_id] = {
                'id': art_id,
                'title': title,
                'description': desc,
                'path': link,
                'filename': link.split('/')[-1],
                'pillar_id': current_pillar['id'],
                'module_id': current_module['id'],
                'category': current_pillar['name'],
                'content': content,
                'search_text': f"{title} {desc}".lower(),
                'is_readme': link.endswith('README.md')
            }

            # Arama İndeksi
            search_index.append({
                'id': art_id,
                'title': title,
                'path': link,
                'pillar_id': current_pillar['id'],
                'module_id': current_module['id'],
                'category': current_pillar['name'],
                'description': desc
            })

    # Dosyalara kaydet
    hierarchy_file = out_dir / "hierarchy.json"
    articles_file = out_dir / "articles.json"
    search_file = out_dir / "search_index.json"

    with open(hierarchy_file, 'w', encoding='utf-8') as f:
        json.dump(pillars, f, ensure_ascii=False, indent=2)

    with open(articles_file, 'w', encoding='utf-8') as f:
        json.dump(articles_map, f, ensure_ascii=False)

    with open(search_file, 'w', encoding='utf-8') as f:
        json.dump(search_index, f, ensure_ascii=False, indent=2)

    print(f"  ✓ {lang_code.upper()}: {len(pillars)} kategori, {len(articles_map)} makale kaydedildi.")

def main():
    print("=== HackTricks Vault İçerik Çıkarıcı Başlatılıyor ===")
    parse_language(EN_SRC, ASSETS_DIR / "en", "en")
    parse_language(TR_SRC, ASSETS_DIR / "tr", "tr")

    # Global istatistikler
    stats = {
        "languages": ["tr", "en"],
        "default_language": "tr",
        "generated_at": str(os.popen("date").read().strip())
    }
    with open(ASSETS_DIR / "stats.json", 'w', encoding='utf-8') as f:
        json.dump(stats, f, indent=2)

    print("\n[✓] Tüm içerikler başarıyla çıkarıldı ve hazırlandı!")

if __name__ == "__main__":
    main()
