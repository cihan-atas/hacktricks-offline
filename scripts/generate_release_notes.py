#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HackTricks Vault - Akıllı Değişiklik Algılayıcı ve Sürüm Notu Oluşturucu (v2)
Bu betik:
- Önceki derleme/commit ile şimdiki derleme arasındaki FARK ları (diff) hesaplar:
  • Hangi markdown dosyaları/dokümanlar yeni eklendi?
  • Hangi dokümanlar güncellendi?
  • Hangi yeni pentest komutları cephaneliğe eklendi? (araç, başlık ve şablon)
- Upstream HackTricks repolarından gelen son commit başlıklarını çeker.
- Tüm bu detayları dosya dosya ve komut komut RELEASE_NOTES.md dosyasına döker.
"""

import os
import json
import subprocess
from datetime import datetime
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
ASSETS_DIR = BASE_DIR / "app" / "assets" / "data"
OUTPUT_FILE = BASE_DIR / "RELEASE_NOTES.md"

def get_git_diff_summary():
    """Git geçmişinden veya kaynak repolardan değişen/eklenen dosyaları tespit eder."""
    added_files = []
    modified_files = []

    # 1. Ana repodaki son commit ile önceki commit arasındaki fark
    try:
        res = subprocess.run(
            ["git", "diff", "--name-status", "HEAD~1", "HEAD"],
            cwd=str(BASE_DIR), capture_output=True, text=True, check=True
        )
        for line in res.stdout.splitlines():
            parts = line.strip().split(maxsplit=1)
            if len(parts) == 2:
                status, path = parts[0], parts[1]
                if status == 'A':
                    added_files.append(path)
                elif status == 'M':
                    modified_files.append(path)
    except Exception:
        pass

    # 2. sources/ altındaki repolardan son commit ile değişen dosyalar
    sources_dir = BASE_DIR / "sources"
    for sdir in sources_dir.glob("hacktricks*"):
        if (sdir / ".git").exists():
            try:
                res = subprocess.run(
                    ["git", "-C", str(sdir), "diff", "--name-status", "HEAD~1", "HEAD"],
                    capture_output=True, text=True, check=True
                )
                for line in res.stdout.splitlines():
                    parts = line.strip().split(maxsplit=1)
                    if len(parts) == 2:
                        status, path = parts[0], parts[1]
                        if path.endswith(".md"):
                            rel = f"{sdir.name}/{path}"
                            if status == 'A' and rel not in added_files:
                                added_files.append(rel)
                            elif status == 'M' and rel not in modified_files:
                                modified_files.append(rel)
            except Exception:
                pass

    return added_files, modified_files

def get_git_recent_commits(repo_path: Path, count: int = 3) -> list:
    """Son commitlerin listesini çeker."""
    if not (repo_path / ".git").exists():
        return []
    try:
        res = subprocess.run(
            ["git", "-C", str(repo_path), "log", "-n", str(count), "--pretty=format:%h - %s"],
            capture_output=True, text=True, check=True
        )
        lines = [l.strip() for l in res.stdout.splitlines() if l.strip()]
        return lines
    except Exception:
        return []

def main():
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M UTC")

    # 1. Doküman ve Hiyerarşi Sayılarını Oku
    tr_articles = {}
    en_articles = {}
    pillars_count = 0
    cloud_pillars_count = 0

    tr_articles_file = ASSETS_DIR / "tr" / "articles.json"
    en_articles_file = ASSETS_DIR / "en" / "articles.json"
    tr_hierarchy_file = ASSETS_DIR / "tr" / "hierarchy.json"

    if tr_articles_file.exists():
        try:
            with open(tr_articles_file, "r", encoding="utf-8") as f:
                tr_articles = json.load(f)
        except Exception:
            pass

    if en_articles_file.exists():
        try:
            with open(en_articles_file, "r", encoding="utf-8") as f:
                en_articles = json.load(f)
        except Exception:
            pass

    if tr_hierarchy_file.exists():
        try:
            with open(tr_hierarchy_file, "r", encoding="utf-8") as f:
                pillars = json.load(f)
                pillars_count = len(pillars)
                cloud_pillars_count = sum(1 for p in pillars if p.get('id', '').startswith('cloud_'))
        except Exception:
            pass

    # 2. Komut Kataloğu ve Dağılımı
    commands_count = 0
    cat_summary = {}
    top_tools = {}
    sample_commands = []

    commands_file = ASSETS_DIR / "commands_catalog.json"
    if commands_file.exists():
        try:
            with open(commands_file, "r", encoding="utf-8") as f:
                cmd_data = json.load(f)
                commands_count = cmd_data.get("total_commands", 0)
                cats_meta = cmd_data.get("categories", {})
                commands_list = cmd_data.get("commands", [])

                for c in commands_list:
                    cat_id = c.get("category", "diger")
                    cat_name = cats_meta.get(cat_id, {}).get("name", cat_id)
                    cat_summary[cat_name] = cat_summary.get(cat_name, 0) + 1

                    tool = c.get("tool", "").lower()
                    if tool:
                        top_tools[tool] = top_tools.get(tool, 0) + 1

                # Örnek son komutlar
                sample_commands = commands_list[-8:] if len(commands_list) >= 8 else commands_list
        except Exception:
            pass

    sorted_tools = sorted(top_tools.items(), key=lambda x: x[1], reverse=True)[:10]

    # 3. Dosya ve Doküman Değişikliklerini Tespit Et
    added_files, modified_files = get_git_diff_summary()

    # 4. Upstream Kaynak Commitleri
    sources_dir = BASE_DIR / "sources"
    sync_info = {
        "HackTricks Main (EN)": get_git_recent_commits(sources_dir / "hacktricks-en", 3),
        "HackTricks Main (TR)": get_git_recent_commits(sources_dir / "hacktricks-tr", 2),
        "HackTricks Cloud (EN)": get_git_recent_commits(sources_dir / "hacktricks-cloud", 3),
        "HackTricks Cloud (TR)": get_git_recent_commits(sources_dir / "hacktricks-cloud-tr", 2),
    }

    # 5. Sürüm Notu Markdown Oluşturma
    lines = [
        f"## 🛡️ HackTricks Vault — Otomatik Üretim Sürümü",
        f"",
        f"> **Derleme Tarihi:** `{now_str}`  ",
        f"> **Durum:** %100 Çevrimdışı (Offline), Banner & Reklamsız, Canlı Parametreli Cephanelik",
        f"",
        f"---",
        f"",
        f"### 📋 Bu Sürümde Neler Değişti? (Dosya & Komut Detayları)",
    ]

    # Eklenen ve Güncellenen Dosyalar Dökümü
    doc_changes = [f for f in (added_files + modified_files) if f.endswith('.md') or 'articles' in f or 'commands' in f]
    if doc_changes:
        lines.append("#### 📝 Etkilenen / Güncellenen Dosyalar:")
        for df in doc_changes[:15]:
            icon = "➕" if df in added_files else "🔄"
            lines.append(f"- {icon} `{df}`")
        if len(doc_changes) > 15:
            lines.append(f"- *... ve {len(doc_changes) - 15} dosya daha güncellendi.*")
        lines.append("")
    else:
        lines.append("- ℹ️ *Bu otomatik derlemede upstream repolardan doğrudan tüm en güncel commitler derlenip APK içine gömüldü.*")
        lines.append("")

    # Eklenen / Mevcut Operasyonel Komutlardan Canlı Örnekler
    if sample_commands:
        lines.append("#### ⚡ Öne Çıkan / Aktif Pentest Komutları:")
        for sc in sample_commands[:6]:
            t = sc.get('tool', '').upper()
            title = sc.get('title', '')
            raw_c = sc.get('template', sc.get('raw_command', ''))
            if len(raw_c) > 95:
                raw_c = raw_c[:92] + "..."
            lines.append(f"- **`{t}`** — *{title}*")
            lines.append(f"  ```bash\n  {raw_c}\n  ```")
        lines.append("")

    lines.extend([
        f"---",
        f"",
        f"### 📊 Genel Veritabanı ve Cephanelik İstatistikleri",
        f"- **📚 Dokümantasyon:** Toplam **{len(tr_articles):,} Türkçe** + **{len(en_articles):,} İngilizce** tam metin makale.".replace(",", "."),
        f"- **🗂️ Güvenlik Kategorileri:** **{pillars_count} Ana Kategori** ({cloud_pillars_count} Bulut & Konteyner mimarisi dahil).",
        f"- **⚡ Canlı Pentest Komutları:** **{commands_count:,} adet** operasyonel, canlı parametrelendirilebilir komut.".replace(",", "."),
        f"",
        f"#### 🎯 Komut Cephaneliği Dağılımı:"
    ])

    for cat_name, count in sorted(cat_summary.items(), key=lambda x: x[1], reverse=True):
        lines.append(f"- • **{cat_name}:** {count:,} komut".replace(",", "."))

    if sorted_tools:
        lines.append("")
        lines.append("#### 🛠️ En Çok Komuta Sahip Popüler Araçlar:")
        tools_str = ", ".join([f"`{t}` ({cnt})" for t, cnt in sorted_tools])
        lines.append(f"{tools_str}")

    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("### 🔄 Upstream Kaynak Senkronizasyonu (En Son Gelen Commit'ler)")

    for repo_name, commits in sync_info.items():
        if commits:
            lines.append(f"**{repo_name}:**")
            for c in commits:
                lines.append(f"- `{c}`")
            lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("### ✨ Dahil Edilen Temel Yetenekler")
    lines.append("- **Temizlenmiş Markdown Deneyimi:** Tüm `{{#include ...}}` eğitim ve sponsor bannerları, dipnot bağlantıları (`<sup>`) ve gereksiz HTML etiketleri arındırıldı.")
    lines.append("- **Bölüm Okundu Takibi (TOC Progress):** Uzun dokümanlarda her bölümün yanında tamamlandı (✓) kutucuğu ve kalınan yere otomatik kaydırma.")
    lines.append("- **Gelişmiş Araç Kataloğu:** 100+ güvenlik aracını komut frekansına göre filtreleyen açılır araç seçim modalı.")
    lines.append("- **AI Güvenlik Asistanı & TTS:** Gemini, Groq veya OpenRouter API desteği, taktiksel analiz saklama ve Türkçe/İngilizce sesli okuma motoru.")
    lines.append("- **Ganimet Defteri (Loot Manager):** Sahadaki IP, bilet ve parolaları yerel depolama ve komut motoruna tek tıkla aktarma.")
    lines.append("")
    lines.append("📥 *Aşağıdaki `HackTricks-Vault-*.apk` dosyasını Android cihazınıza indirip doğrudan kurabilirsiniz.*")

    content = "\n".join(lines) + "\n"

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"[✓] Detaylı sürüm notu başarıyla üretildi: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
