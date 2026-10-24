#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HackTricks Vault — Akıllı Komut Çıkarıcı & Cephanelik (Arsenal) Üreticisi
Bu betik:
1. HackTricks dokümanlarını tarar.
2. Sadece operasyonel siber güvenlik araçlarını ve çalıştırılabilir komutları filtreler.
3. Parametreleri akıllı yer tutuculara ({TARGET_IP}, {LHOST}, {LPORT}, vb.) dönüştürür.
4. 6 Operasyonel Faz (Kill Chain) altında kategorize eder.
5. 'app/assets/data/commands_catalog.json' dosyasına kaydeder.
"""

import os
import re
import json
import hashlib
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
EN_SRC = BASE_DIR / "sources" / "hacktricks-en" / "src"
TR_SRC = BASE_DIR / "sources" / "hacktricks-tr" / "src"
OUTPUT_FILE = BASE_DIR / "app" / "assets" / "data" / "commands_catalog.json"

CATEGORIES = {
    "recon": {
        "id": "recon",
        "name": "Keşif & Ağ Taraması",
        "name_en": "Recon & Network Scanning",
        "icon": "radar",
        "color": "#38bdf8",  # Cyan
    },
    "web": {
        "id": "web",
        "name": "Web & Dizin Fuzzing",
        "name_en": "Web Security & Fuzzing",
        "icon": "language",
        "color": "#f59e0b",  # Amber
    },
    "services": {
        "id": "services",
        "name": "Ağ Servisleri İstismarı",
        "name_en": "Network Services Exploitation",
        "icon": "router",
        "color": "#a855f7",  # Purple
    },
    "shells_pivoting": {
        "id": "shells_pivoting",
        "name": "Reverse Shell & Tünelleme",
        "name_en": "Reverse Shells & Pivoting",
        "icon": "terminal",
        "color": "#10b981",  # Emerald
    },
    "privesc": {
        "id": "privesc",
        "name": "Yetki Yükseltme (PrivEsc)",
        "name_en": "Privilege Escalation",
        "icon": "arrow_upward",
        "color": "#ef4444",  # Red
    },
    "auth_cracking": {
        "id": "auth_cracking",
        "name": "Kimlik & Parola Kırma",
        "name_en": "Auth & Password Cracking",
        "icon": "lock_open",
        "color": "#ec4899",  # Pink
    }
}

TOOL_RULES = [
    # 1. Recon
    (r'^\s*(nmap|masscan|snmpwalk|whatweb|sublist3r|amass|assetfinder|subfinder)\b', 'recon'),
    (r'^\s*nikto\b', 'recon'),
    (r'^\s*wpscan\b', 'recon'),

    # 2. Web & Fuzzing
    (r'^\s*(ffuf|gobuster|feroxbuster|dirsearch|wfuzz|arjun|nuclei)\b', 'web'),
    (r'^\s*(sqlmap|commix|ghauri)\b', 'web'),

    # 3. Network Services
    (r'^\s*(smbclient|crackmapexec|netexec|nxc|rpcclient|evil-winrm)\b', 'services'),
    (r'^\s*impacket-\w+\b', 'services'),
    (r'^\s*(ldapsearch|redis-cli|mongo|mysql|mssqlclient|showmount)\b', 'services'),

    # 4. Shells & Pivoting
    (r'^\s*(chisel|socat|ligolo-ng|plink)\b', 'shells_pivoting'),
    (r'^\s*(nc|ncat|netcat)\b.*(-e|-c|/bin/sh|/bin/bash)', 'shells_pivoting'),
    (r'bash\s+-i\s+>&', 'shells_pivoting'),
    (r'python[23]?\s+-c.*socket', 'shells_pivoting'),
    (r'php\s+-r.*fsockopen', 'shells_pivoting'),
    (r'powershell.*Net\.Sockets', 'shells_pivoting'),
    (r'ssh\s+.*-(?:[LRD]|D)\s+\d+', 'shells_pivoting'),

    # 5. PrivEsc
    (r'^\s*(linpeas|winpeas|powerup|juicypotato|printspoofer|godpotato|sweetpotato)\b', 'privesc'),
    (r'^\s*sudo\s+-l\b', 'privesc'),
    (r'find\s+/\s+-perm\s+-(?:4000|2000|u=s)', 'privesc'),
    (r'^\s*(getcap|capsh)\b', 'privesc'),
    (r'certutil(?:\.exe)?\s+-urlcache', 'privesc'),

    # 6. Auth & Cracking
    (r'^\s*(hashcat|john|hydra|medusa|crowbar)\b', 'auth_cracking'),
    (r'^\s*(mimikatz|rubeus|certipy|bloodhound)\b', 'auth_cracking'),
]

# Yer tutucu dönüştürücüler
IP_REGEX = re.compile(r'\b(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3})\b')
DOMAIN_REGEX = re.compile(r'\b(?:corp\.local|domain\.local|htb\.local|target\.local|victim\.com|example\.com|megacorp\.local)\b', re.IGNORECASE)
URL_REGEX = re.compile(r'https?://[a-zA-Z0-9.-]+(?::\d+)?(?:/[^\s"\']*)?')

def determine_tool_name(cmd: str) -> str:
    parts = cmd.strip().split()
    if not parts:
        return "Command"
    first = parts[0].split('/')[-1]
    if first in ['sudo', 'python', 'python3', 'bash', 'sh'] and len(parts) > 1:
        return parts[1].split('/')[-1]
    return first

def parameterize_command(cmd: str, category_id: str) -> tuple[str, list[str]]:
    """Komut içindeki sabit IP, port, parola ve hedefleri {DEĞİŞKEN} etiketlerine çevirir."""
    vars_found = set()
    res = cmd

    # Açık etiketler (<IP>, <TARGET>, vb.)
    placeholder_rules = [
        (r'<(?:target_ip|target|victim_ip|victim|ip|host)>', '{TARGET_IP}', 'TARGET_IP'),
        (r'<(?:lhost|attacker_ip|attacker|local_ip)>', '{LHOST}', 'LHOST'),
        (r'<(?:lport|local_port)>', '{LPORT}', 'LPORT'),
        (r'<(?:target_port|port|rport)>', '{TARGET_PORT}', 'TARGET_PORT'),
        (r'<(?:user|username|user_name)>', '{USER}', 'USER'),
        (r'<(?:pass|password|pwd)>', '{PASSWORD}', 'PASSWORD'),
        (r'<(?:domain|fqdn|realm)>', '{DOMAIN}', 'DOMAIN'),
        (r'<(?:wordlist|wordlist_path)>', '{WORDLIST}', 'WORDLIST'),
        (r'<(?:url|target_url)>', '{TARGET_URL}', 'TARGET_URL'),
    ]

    for pat, rep, var_name in placeholder_rules:
        if re.search(pat, res, re.IGNORECASE):
            res = re.sub(pat, rep, res, flags=re.IGNORECASE)
            vars_found.add(var_name)

    # LHOST / LPORT (özellikle reverse shell ve pivoting için)
    if category_id == 'shells_pivoting':
        for ip in IP_REGEX.findall(res):
            res = res.replace(ip, "{LHOST}")
            vars_found.add("LHOST")
        res = re.sub(r'\b(?:4444|9001|1337|8443)\b', "{LPORT}", res)
        if "{LPORT}" in res:
            vars_found.add("LPORT")
    else:
        for ip in IP_REGEX.findall(res):
            res = res.replace(ip, "{TARGET_IP}")
            vars_found.add("TARGET_IP")

    # Domain
    for dom in DOMAIN_REGEX.findall(res):
        res = res.replace(dom, "{DOMAIN}")
        vars_found.add("DOMAIN")

    # Wordlists
    if "/usr/share/wordlists/" in res or "/usr/share/seclists/" in res:
        res = re.sub(r'/usr/share/(?:wordlists|seclists)/[^\s"\']+', "{WORDLIST}", res)
        vars_found.add("WORDLIST")

    # Hedef URL
    if "http://" in res or "https://" in res:
        res = re.sub(r'https?://(?:\{TARGET_IP\}|\{DOMAIN\}|[a-zA-Z0-9.-]+)(?::\d+)?', "{TARGET_URL}", res)
        vars_found.add("TARGET_URL")

    # Kullanıcı & Şifre kalıpları
    res = re.sub(r'\b(?:Administrator|admin|root|jdoe)\b(?=:|\s|$)', "{USER}", res)
    if "{USER}" in res:
        vars_found.add("USER")

    res = re.sub(r'\b(?:Password123!?|P@ssw0rd123!?|admin123)\b', "{PASSWORD}", res)
    if "{PASSWORD}" in res:
        vars_found.add("PASSWORD")

    # Genel kelime target son kontrol
    if re.search(r'\btarget\b', res, re.IGNORECASE):
        res = re.sub(r'\btarget\b', "{TARGET_IP}", res, flags=re.IGNORECASE)
        vars_found.add("TARGET_IP")

    return res, sorted(list(vars_found))

def clean_command_line(line: str) -> str:
    """Komut satırındaki shell prompt'larını ($ , # , PS>) temizler."""
    line = re.sub(r'^\s*[$#>]\s*', '', line)
    line = re.sub(r'^\s*(?:PS|c:.*?>)\s*', '', line, flags=re.IGNORECASE)
    line = line.strip()
    return line

def extract_commands_from_file(file_path: Path, relative_path: str) -> list[dict]:
    results = []
    try:
        content = file_path.read_text(encoding='utf-8', errors='ignore')
    except Exception:
        return results

    # Başlık tespiti
    title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
    doc_title = title_match.group(1).strip() if title_match else relative_path

    # Kod bloklarını çıkar
    blocks = re.findall(r'```(?:bash|sh|powershell|cmd|console)?\s*\n(.*?)```', content, re.DOTALL)
    for block in blocks:
        lines = block.splitlines()
        for line in lines:
            cleaned = clean_command_line(line)
            if len(cleaned) < 8 or len(cleaned) > 280:
                continue
            if cleaned.startswith(('echo ', 'cat ', 'ls ', 'cd ', 'mkdir ', 'rm ', 'chmod ')):
                continue
            # Output çıktısı mı? (Örn: [!] Error, Listening on...)
            if cleaned.startswith(('[*]', '[+]', '[-]', '[!]', 'Total', 'Usage:', 'Error')):
                continue

            # Tool Rules ile eşleştir
            for pattern, cat_id in TOOL_RULES:
                if re.search(pattern, cleaned, re.IGNORECASE):
                    tool_name = determine_tool_name(cleaned)
                    template, variables = parameterize_command(cleaned, cat_id)

                    cmd_id = hashlib.md5(cleaned.encode('utf-8')).hexdigest()[:12]
                    results.append({
                        "id": cmd_id,
                        "title": f"{tool_name.upper()} — {doc_title}",
                        "tool": tool_name.lower(),
                        "category": cat_id,
                        "raw_command": cleaned,
                        "template": template,
                        "variables": variables,
                        "doc_title": doc_title,
                        "doc_path": relative_path,
                    })
                    break

    return results

def main():
    print("=== HackTricks Arsenal (Akıllı Komut Çıkarıcı) Başlatılıyor ===")
    all_commands = []
    seen_commands = set()

    # İngilizce ve Türkçe kaynakları tara
    sources = [
        (EN_SRC, "EN"),
        (TR_SRC, "TR")
    ]

    for src_dir, lang in sources:
        if not src_dir.exists():
            continue
        print(f"[+] '{lang}' dokümanları taranıyor...")
        for md_file in src_dir.rglob("*.md"):
            rel_path = str(md_file.relative_to(src_dir))
            extracted = extract_commands_from_file(md_file, rel_path)
            for item in extracted:
                norm = item["template"].strip().lower()
                if norm not in seen_commands:
                    seen_commands.add(norm)
                    all_commands.append(item)

    # İstatistikler
    cat_counts = {}
    for c in all_commands:
        cat_counts[c["category"]] = cat_counts.get(c["category"], 0) + 1

    catalog = {
        "categories": CATEGORIES,
        "total_commands": len(all_commands),
        "commands": all_commands
    }

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)

    print(f"\n[✓] Toplam {len(all_commands)} adet temizlenmiş operasyonel komut çıkarıldı!")
    print("    Kategori dağılımı:")
    for cat_id, count in cat_counts.items():
        name = CATEGORIES.get(cat_id, {}).get("name", cat_id)
        print(f"      • {name}: {count} komut")
    print(f"[✓] Kaydedildi: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
