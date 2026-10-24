#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HackTricks Vault - Evrensel İçerik Çıkarıcı ve İndeksleyici v3
Bu betik:
- 'sources/hacktricks-en/src' (Genel HackTricks İngilizce - 1.130 makale)
- 'sources/hacktricks-cloud/src' (HackTricks Cloud - 1.800+ bulut makalesi)
- 'sources/hacktricks-tr/src' (Genel HackTricks Türkçe - 1.130 makale)
dizinlerini tarar ve birleştirilmiş, optimize edilmiş hiyerarşik JSON verileri üretir:
  app/assets/data/en/
  app/assets/data/tr/
"""

import os
import re
import json
import hashlib
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
EN_SRC = BASE_DIR / "sources" / "hacktricks-en" / "src"
CLOUD_EN_SRC = BASE_DIR / "sources" / "hacktricks-cloud" / "src"
CLOUD_TR_SRC = BASE_DIR / "sources" / "hacktricks-cloud-tr" / "src"
TR_SRC = BASE_DIR / "sources" / "hacktricks-tr" / "src"
ASSETS_DIR = BASE_DIR / "app" / "assets" / "data"

PILLAR_COLORS = [
    "#ef4444", "#f97316", "#f59e0b", "#10b981", "#06b6d4",
    "#3b82f6", "#6366f1", "#8b5cf6", "#d946ef", "#ec4899",
    "#14b8a6", "#84cc16", "#eab308", "#a855f7", "#0284c7",
    "#38bdf8", "#4ade80", "#fb7185", "#f43f5e", "#64748b",
    "#0ea5e9", "#22c55e", "#e11d48", "#7c3aed", "#d97706", "#2563eb"
]

CLOUD_PILLARS_META = {
    'cloud_aws': {
        'id': 'cloud_aws',
        'name_en': '☁️ AWS Pentesting & Security',
        'name_tr': '☁️ AWS Bulut Güvenliği & Pentest',
        'subtitle_en': 'Amazon Web Services IAM, S3, EC2, Lambda, Secrets & Privilege Escalation',
        'subtitle_tr': 'Amazon Web Services IAM, S3, EC2, Lambda, Yetki Yükseltme ve Zafiyetler',
        'color': '#ff9900'
    },
    'cloud_azure': {
        'id': 'cloud_azure',
        'name_en': '🔷 Azure & Entra ID Pentesting',
        'name_tr': '🔷 Azure & Entra ID Güvenliği & Pentest',
        'subtitle_en': 'Microsoft Azure, Entra ID (Azure AD), Key Vault, App Services & RBAC Abuse',
        'subtitle_tr': 'Microsoft Azure, Entra ID (Azure AD), Key Vault, Uygulama ve Yetki İstismarı',
        'color': '#0089d6'
    },
    'cloud_gcp': {
        'id': 'cloud_gcp',
        'name_en': '🌐 Google Cloud (GCP) Security',
        'name_tr': '🌐 Google Cloud (GCP) Güvenliği & Pentest',
        'subtitle_en': 'Google Cloud Platform IAM, Storage, GKE, Cloud Functions & Exploitation',
        'subtitle_tr': 'Google Cloud Platform IAM, Storage, GKE, Cloud Functions ve Sömürü',
        'color': '#4285f4'
    },
    'cloud_k8s': {
        'id': 'cloud_k8s',
        'name_en': '☸️ Kubernetes & Container Security',
        'name_tr': '☸️ Kubernetes & Konteyner Güvenliği',
        'subtitle_en': 'Kubernetes (K8s), Docker, Helm, RBAC, Control-Plane, Pod Escapes & Clusters',
        'subtitle_tr': 'Kubernetes (K8s), Docker, Helm, RBAC, Pod Kaçışları ve Küme Güvenliği',
        'color': '#326ce5'
    },
    'cloud_cicd': {
        'id': 'cloud_cicd',
        'name_en': '🏭 CI/CD & Supply Chain Security',
        'name_tr': '🏭 CI/CD & Tedarik Zinciri Güvenliği',
        'subtitle_en': 'GitHub Actions, GitLab CI, Jenkins, Concourse, TeamCity, Airflow & Pipelines',
        'subtitle_tr': 'GitHub Actions, GitLab CI, Jenkins, TeamCity ve Boru Hattı Güvenliği',
        'color': '#10b981'
    },
    'cloud_other': {
        'id': 'cloud_other',
        'name_en': '🚀 Multi-Cloud & Workspace Security',
        'name_tr': '🚀 Çoklu Bulut & Çalışma Alanı Güvenliği',
        'subtitle_en': 'DigitalOcean, OpenShift, IBM Cloud, Google Workspace & Cloud Methodology',
        'subtitle_tr': 'DigitalOcean, OpenShift, IBM Cloud, Google Workspace ve Bulut Metodolojisi',
        'color': '#8b5cf6'
    }
}

def clean_markdown(content: str) -> str:
    """GitBook / mdBook özel etiketlerini temizle ve Flutter Markdown için optimize et."""
    # GitHub Secret Scanning koruması: Örnek dummy bulut token'larını güvenli yer tutuculara çevir
    content = re.sub(r'1//0[a-zA-Z0-9_\-]+', '{{google_refresh_token}}', content)
    content = re.sub(r'ya29\.[a-zA-Z0-9_\-]+', '{{google_oauth_token}}', content)
    content = re.sub(r'AIza[0-9A-Za-z-_]{35}', '{{google_api_key}}', content)
    content = re.sub(r'AKIA[0-9A-Z]{16}', '{{aws_access_key}}', content)

    content = re.sub(r'\{%\s*hint\s+style="(\w+)"\s*%\}(.*?)\{%\s*endhint\s*%\}', r'> **[\1]** \2', content, flags=re.DOTALL)
    content = re.sub(r'\{%\s*hint[^\%]*%\}(.*?)\{%\s*endhint\s*%\}', r'> \1', content, flags=re.DOTALL)
    content = re.sub(r'\{%\s*(?:hint|endhint)[^\%]*%\}', '', content)
    content = re.sub(r'<!--\s*(?:tabs|endtabs)\s*-->', '', content)
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

def get_cloud_pillar_id(link: str) -> str:
    """Bulut dokümanının dosya yoluna göre ilgili bulut kategorisini belirler."""
    l = link.lower()
    if 'workspace-security' in l or 'gws-' in l:
        return 'cloud_other'
    elif 'aws-security' in l or '/aws/' in l:
        return 'cloud_aws'
    elif 'azure-security' in l or '/azure/' in l or 'entra' in l:
        return 'cloud_azure'
    elif 'gcp-security' in l or '/gcp/' in l:
        return 'cloud_gcp'
    elif 'kubernetes' in l or 'k8s' in l or 'container' in l or 'openshift' in l:
        return 'cloud_k8s'
    elif 'pentesting-ci-cd' in l or 'github' in l or 'gitlab' in l or 'jenkins' in l or 'airflow' in l:
        return 'cloud_cicd'
    else:
        return 'cloud_other'

def parse_main_wiki(src_dir: Path, color_offset: int = 0):
    summary_path = src_dir / "SUMMARY.md"
    if not summary_path.exists():
        return [], {}, []

    with open(summary_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    pillars = []
    current_pillar = None
    articles_map = {}
    search_index = []
    color_idx = color_offset
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
                except Exception:
                    pass

            art_id = hashlib.md5(f"main_{link}".encode('utf-8')).hexdigest()[:12]

            art_summary = {
                'id': art_id,
                'title': title,
                'description': desc,
                'path': link,
                'is_readme': link.endswith('README.md')
            }

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

            search_index.append({
                'id': art_id,
                'title': title,
                'path': link,
                'pillar_id': current_pillar['id'],
                'module_id': current_module['id'],
                'category': current_pillar['name'],
                'description': desc
            })

    return pillars, articles_map, search_index

def parse_cloud_wiki(src_dir: Path, lang: str):
    summary_path = src_dir / "SUMMARY.md"
    if not summary_path.exists():
        return [], {}, []

    pillars_map = {}
    for pid, meta in CLOUD_PILLARS_META.items():
        name = meta['name_tr'] if lang == 'tr' else meta['name_en']
        sub = meta['subtitle_tr'] if lang == 'tr' else meta['subtitle_en']
        pillars_map[pid] = {
            'id': pid,
            'name': name,
            'subtitle': sub,
            'dir': pid,
            'color': meta['color'],
            'featured_articles': [],
            'modules': []
        }

    with open(summary_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    articles_map = {}
    search_index = []
    current_modules = {}

    for line in lines:
        raw = line.rstrip()
        m = re.match(r'^(\s*)[-*]\s*\[(.*?)\]\((.*?)\)', raw)
        if not m:
            continue

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
            except Exception:
                pass

        pid = get_cloud_pillar_id(link)
        pillar = pillars_map[pid]
        art_id = hashlib.md5(f"cloud_{link}".encode('utf-8')).hexdigest()[:12]

        art_summary = {
            'id': art_id,
            'title': title,
            'description': desc,
            'path': link,
            'is_readme': link.endswith('README.md')
        }

        curr_mod = current_modules.get(pid)
        is_new_module = (indent <= 2) or curr_mod is None
        if is_new_module:
            curr_mod = {
                'id': art_id,
                'folder': link.split('/')[0] if '/' in link else '',
                'title': title,
                'path': link,
                'has_subcategories': False,
                'subcategories': [],
                'articles': [art_summary]
            }
            pillar['modules'].append(curr_mod)
            current_modules[pid] = curr_mod
        else:
            curr_mod['articles'].append(art_summary)

        articles_map[art_id] = {
            'id': art_id,
            'title': title,
            'description': desc,
            'path': link,
            'filename': link.split('/')[-1],
            'pillar_id': pid,
            'module_id': curr_mod['id'],
            'category': pillar['name'],
            'content': content,
            'search_text': f"{title} {desc}".lower(),
            'is_readme': link.endswith('README.md')
        }

        search_index.append({
            'id': art_id,
            'title': title,
            'path': link,
            'pillar_id': pid,
            'module_id': curr_mod['id'],
            'category': pillar['name'],
            'description': desc
        })

    # Boş kalan sütunları filtrele
    final_pillars = [p for p in pillars_map.values() if len(p['modules']) > 0]
    return final_pillars, articles_map, search_index

def build_combined_language(main_src: Path, cloud_src: Path, out_dir: Path, lang: str):
    print(f"[+] '{lang.upper()}' dili işleniyor...")
    out_dir.mkdir(parents=True, exist_ok=True)

    # 1. Ana HackTricks
    if not (main_src / "SUMMARY.md").exists():
        if lang == 'tr' and (EN_SRC / "SUMMARY.md").exists():
            print(f"[!] UYARI: {main_src} bulunamadı! EN kaynaklarına fallback yapılıyor...")
            main_src = EN_SRC
        else:
            raise FileNotFoundError(f"HATA: HackTricks SUMMARY.md bulunamadı: {main_src}")

    main_pillars, main_articles, main_search = parse_main_wiki(main_src, color_offset=0)
    if len(main_pillars) == 0:
        raise ValueError(f"HATA: {main_src} dizininden hiçbir ana kategori çıkarılamadı!")

    # 2. HackTricks Cloud
    if not (cloud_src / "SUMMARY.md").exists():
        raise FileNotFoundError(f"HATA: HackTricks Cloud SUMMARY.md bulunamadı: {cloud_src}")

    cloud_pillars, cloud_articles, cloud_search = parse_cloud_wiki(cloud_src, lang=lang)
    if len(cloud_pillars) == 0:
        raise ValueError(f"HATA: {cloud_src} dizininden hiçbir bulut kategorisi çıkarılamadı!")

    # 3. Birleştir
    all_pillars = main_pillars + cloud_pillars
    all_articles = {**main_articles, **cloud_articles}
    all_search = main_search + cloud_search

    # 4. Dosyalara Kaydet
    with open(out_dir / "hierarchy.json", 'w', encoding='utf-8') as f:
        json.dump(all_pillars, f, ensure_ascii=False, indent=2)

    with open(out_dir / "articles.json", 'w', encoding='utf-8') as f:
        json.dump(all_articles, f, ensure_ascii=False)

    with open(out_dir / "search_index.json", 'w', encoding='utf-8') as f:
        json.dump(all_search, f, ensure_ascii=False, indent=2)

    print(f"  ✓ {lang.upper()}: Toplam {len(all_pillars)} kategori ({len(cloud_pillars)} Bulut), {len(all_articles)} makale kaydedildi.")

def main():
    print("=== HackTricks Vault (Main + Cloud) İçerik Çıkarıcı Başlatılıyor ===")
    
    # 1. İngilizce (Main EN + Cloud EN)
    print("[-] İngilizce içerikler (Main EN + Cloud EN) derleniyor...")
    build_combined_language(EN_SRC, CLOUD_EN_SRC, ASSETS_DIR / "en", "en")

    # 2. Türkçe (Main TR + Cloud TR)
    cloud_tr = CLOUD_TR_SRC if CLOUD_TR_SRC.exists() else CLOUD_EN_SRC
    if cloud_tr == CLOUD_TR_SRC:
        print("[-] Türkçe içerikler (Main TR + Cloud TR) derleniyor...")
    else:
        print("[!] UYARI: sources/hacktricks-cloud-tr bulunamadı, Cloud EN fallback kullanılıyor.")
    build_combined_language(TR_SRC, cloud_tr, ASSETS_DIR / "tr", "tr")

    # Global istatistikler
    stats = {
        "languages": ["tr", "en"],
        "default_language": "tr",
        "has_cloud": True,
        "generated_at": str(os.popen("date").read().strip())
    }
    with open(ASSETS_DIR / "stats.json", 'w', encoding='utf-8') as f:
        json.dump(stats, f, indent=2)

    print("\n[✓] Hem Ana HackTricks hem de HackTricks Cloud başarıyla birleştirildi!")

if __name__ == "__main__":
    main()
