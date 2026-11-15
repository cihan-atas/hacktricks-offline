#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HackTricks Vault - Dinamik Sürüm Notu ve Değişiklik Günlüğü (Changelog) Oluşturucu
Bu betik:
- Toplam doküman sayılarını (TR ve EN)
- Kategori (Pillar) ve modül dağılımını
- Çıkarılan canlı pentest komutlarının sayısını ve kategorik dökümünü
- En çok komuta sahip güvenlik araçlarını
- Upstream HackTricks ve HackTricks Cloud repolarından senkronize edilen son güncellemeleri
okur ve GitHub Release için zengin, profesyonel bir Markdown sürüm notu (RELEASE_NOTES.md) üretir.
"""

import os
import json
import subprocess
from datetime import datetime
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
ASSETS_DIR = BASE_DIR / "app" / "assets" / "data"
OUTPUT_FILE = BASE_DIR / "RELEASE_NOTES.md"

def get_git_latest_commit(repo_path: Path) -> str:
    """Git reposundan son commit özetini çeker."""
    if not (repo_path / ".git").exists():
        return "N/A"
    try:
        res = subprocess.run(
            ["git", "-C", str(repo_path), "log", "-n", "1", "--pretty=format:%h - %s (%cd)", "--date=short"],
            capture_output=True, text=True, check=True
        )
        return res.stdout.strip()
    except Exception:
        return "N/A"

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

    # 1. Doküman Sayılarını Oku
    tr_articles_count = 0
    en_articles_count = 0
    pillars_count = 0
    cloud_pillars_count = 0

    tr_articles_file = ASSETS_DIR / "tr" / "articles.json"
    en_articles_file = ASSETS_DIR / "en" / "articles.json"
    tr_hierarchy_file = ASSETS_DIR / "tr" / "hierarchy.json"

    if tr_articles_file.exists():
        try:
            with open(tr_articles_file, "r", encoding="utf-8") as f:
                tr_articles_count = len(json.load(f))
        except Exception:
            pass

    if en_articles_file.exists():
        try:
            with open(en_articles_file, "r", encoding="utf-8") as f:
                en_articles_count = len(json.load(f))
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

    # 2. Komut Kataloğunu Oku
    commands_count = 0
    cat_summary = {}
    top_tools = {}

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
        except Exception:
            pass

    sorted_tools = sorted(top_tools.items(), key=lambda x: x[1], reverse=True)[:10]

    # 3. Upstream Repolardan Senkronizasyon Durumu
    sources_dir = BASE_DIR / "sources"
    sync_info = {
        "HackTricks Main (EN)": get_git_recent_commits(sources_dir / "hacktricks-en", 3),
        "HackTricks Main (TR)": get_git_recent_commits(sources_dir / "hacktricks-tr", 2),
        "HackTricks Cloud (EN)": get_git_recent_commits(sources_dir / "hacktricks-cloud", 3),
        "HackTricks Cloud (TR)": get_git_recent_commits(sources_dir / "hacktricks-cloud-tr", 2),
    }

    # 4. Markdown Notunu Oluştur
    lines = [
        f"## 🛡️ HackTricks Vault — Otomatik Üretim Sürümü",
        f"",
        f"> **Derleme Tarihi:** `{now_str}`  ",
        f"> **Durum:** %100 Çevrimdışı (Offline), Banner & Reklamsız, Canlı Parametreli Cephanelik",
        f"",
        f"---",
        f"",
        f"### 📊 Genel Veritabanı ve Cephanelik İstatistikleri",
        f"- **📚 Dokümantasyon:** Toplam **{tr_articles_count:,} Türkçe** + **{en_articles_count:,} İngilizce** tam metin makale.".replace(",", "."),
        f"- **🗂️ Güvenlik Kategorileri:** **{pillars_count} Ana Kategori** ({cloud_pillars_count} Bulut & Konteyner mimarisi dahil).",
        f"- **⚡ Canlı Pentest Komutları:** **{commands_count:,} adet** operasyonel, canlı parametrelendirilebilir komut.".replace(",", "."),
        f"",
        f"#### 🎯 Komut Cephaneliği Dağılımı:"
    ]

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
    lines.append("### 🔄 Upstream Kaynak Senkronizasyonu (En Son Gelen Güncellemeler)")

    has_upstream_logs = False
    for repo_name, commits in sync_info.items():
        if commits:
            has_upstream_logs = True
            lines.append(f"**{repo_name}:**")
            for c in commits:
                lines.append(f"- `{c}`")
            lines.append("")

    if not has_upstream_logs:
        lines.append("- Upstream repolar yerel önbellekten veya en güncel `master/tr` dallarından derlendi.")
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

    print(f"[✓] Sürüm notu başarıyla üretildi: {OUTPUT_FILE}")
    print(f"    Doküman: {tr_articles_count} | Komut: {commands_count}")

if __name__ == "__main__":
    main()
