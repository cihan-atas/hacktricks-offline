#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HackTricks Vault — Evrensel Komut ve Cephanelik Çıkarıcısı (Universal Extractor v2)
2.260+ HackTricks dokümanını (EN & TR) derinlemesine tarayarak 2.000+'den fazla
çalıştırılabilir, temiz ve canlı parametrelendirilebilir siber güvenlik komutunu çıkarır.
"""

import os
import re
import json
import glob
import hashlib
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
OUTPUT_FILE = BASE_DIR / "app" / "assets" / "data" / "commands_catalog.json"

# Yer tutucu tespit regex'leri
IP_PATTERNS = [
    r'\b10\.\d{1,3}\.\d{1,3}\.\d{1,3}\b',
    r'\b192\.168\.\d{1,3}\.\d{1,3}\b',
    r'\b172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}\b',
    r'\b127\.0\.0\.1\b'
]

DOMAIN_PATTERNS = [
    r'\bcorp\.local\b', r'\bdomain\.local\b', r'\binlanefreight\.local\b',
    r'\bcontoso\.com\b', r'\blab\.local\b', r'\btarget\.local\b', r'\bhtb\.local\b',
    r'\bexample\.com\b', r'\btest\.local\b', r'\bvulnerable\.domain\b'
]

USERS_LIST = ['admin', 'administrator', 'root', 'user', 'guest', 'jdoe', 'test', 'svc_admin', 'svc_sql']
PASS_LIST = ['password', 'password123', 'password123!', 'admin', 'root', 'toor', 'p@ssword123', 'summer2024!', 'spring2026!']

# Güvenilir Araç Tanımları ve Kategorileri
TOOL_DEFINITIONS = {
    # 1. Recon & Ağ Taraması
    'nmap': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'masscan': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'rustscan': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'arp-scan': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'netdiscover': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'fping': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'hping3': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'tcpdump': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'blue'},
    'tshark': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'blue'},
    'wireshark': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'blue'},
    'dig': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'nslookup': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'dnsrecon': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'dnsenum': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'amass': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'subfinder': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'assetfinder': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'snmpwalk': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'onesixtyone': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'snmp-check': {'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},

    # 2. Web Güvenliği & Fuzzing
    'ffuf': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'gobuster': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'dirsearch': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'feroxbuster': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'wfuzz': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'nikto': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'wpscan': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'sqlmap': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'ghauri': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'commix': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'tplmap': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'xsser': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'dalfox': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'nuclei': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'httpx': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'katana': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'gau': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'waybackurls': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'arjun': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'paramspider': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'jwt_tool': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'curl': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'wget': {'cat': 'web', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},

    # 3. Ağ Servisleri İstismarı
    'smbclient': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'smbmap': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'enum4linux': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'enum4linux-ng': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'rpcclient': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'ldapsearch': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'windapsearch': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'evil-winrm': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'xfreerdp': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'rdesktop': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'mssqlclient.py': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'sqsh': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'mysql': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'psql': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'redis-cli': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'mongo': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'mongosh': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'ssh': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'telnet': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'ftp': {'cat': 'services', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},

    # 4. Active Directory & Windows Domain
    'crackmapexec': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'netexec': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'nxc': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'bloodhound': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'bloodhound-python': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'sharphound': {'cat': 'ad', 'plat': 'Windows CMD / Binary', 'opsec': 'noisy', 'pillar': 'red'},
    'certipy': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'certify': {'cat': 'ad', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'rubeus': {'cat': 'ad', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'mimikatz': {'cat': 'ad', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'secretsdump.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'psexec.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'wmiexec.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'smbexec.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'atexec.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'dcomexec.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'getTGT.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'getST.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'goldenPac.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'ntlmrelayx.py': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'responder': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'mitm6': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'coercer': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'petitpotam': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'printerbug': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'kerbrute': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'bloodyad': {'cat': 'ad', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'powerview': {'cat': 'ad', 'plat': 'PowerShell', 'opsec': 'stealth', 'pillar': 'red'},
    'powerup': {'cat': 'ad', 'plat': 'PowerShell', 'opsec': 'stealth', 'pillar': 'red'},

    # 5. Reverse Shells & Pivoting
    'chisel': {'cat': 'shells_pivoting', 'plat': 'Linux / Cross-Platform', 'opsec': 'stealth', 'pillar': 'red'},
    'ligolo-ng': {'cat': 'shells_pivoting', 'plat': 'Linux / Cross-Platform', 'opsec': 'stealth', 'pillar': 'red'},
    'socat': {'cat': 'shells_pivoting', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'nc': {'cat': 'shells_pivoting', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'ncat': {'cat': 'shells_pivoting', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'netcat': {'cat': 'shells_pivoting', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'msfvenom': {'cat': 'shells_pivoting', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    'msfconsole': {'cat': 'shells_pivoting', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'proxychains': {'cat': 'shells_pivoting', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'sshuttle': {'cat': 'shells_pivoting', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'plink': {'cat': 'shells_pivoting', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},

    # 6. Yetki Yükseltme (Linux & Windows)
    'linpeas': {'cat': 'privesc', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'winpeas': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'noisy', 'pillar': 'red'},
    'seatbelt': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'sharpup': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'pspy': {'cat': 'privesc', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'sudo': {'cat': 'privesc', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'whoami': {'cat': 'privesc', 'plat': 'Linux / Cross-Platform', 'opsec': 'stealth', 'pillar': 'red'},
    'icacls': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'accesschk': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'certutil': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'noisy', 'pillar': 'red'},
    'schtasks': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'wevtutil': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'blue'},
    'wmic': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'printspoofer': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'godpotato': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'juicypotato': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},
    'sweetpotato': {'cat': 'privesc', 'plat': 'Windows CMD / Binary', 'opsec': 'stealth', 'pillar': 'red'},

    # 7. Kimlik Doğrulama & Parola Kırma
    'john': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    'hashcat': {'cat': 'auth_cracking', 'plat': 'Linux / Cross-Platform', 'opsec': 'offline', 'pillar': 'red'},
    'hydra': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'medusa': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'crowbar': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'patator': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'hashid': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    'name-that-hash': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    'nth': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    'ciphey': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    'keepass2john': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    'ssh2john': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    'zip2john': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    '7z2john': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},
    'rar2john': {'cat': 'auth_cracking', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'red'},

    # 8. Bulut & Konteyner
    'aws': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'az': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'gcloud': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'kubectl': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'docker': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'podman': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'helm': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'trivy': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'offline', 'pillar': 'blue'},
    'kube-hunter': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'peirates': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'},
    'scoutsuite': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
    'prowler': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'blue'},
    'pacu': {'cat': 'cloud', 'plat': 'Linux CLI', 'opsec': 'stealth', 'pillar': 'red'},
}

CATEGORIES_META = {
    'recon': {'id': 'recon', 'name': 'Keşif & Ağ Taraması', 'name_en': 'Recon & Network Scanning', 'icon': 'radar', 'color': '#38bdf8'},
    'web': {'id': 'web', 'name': 'Web & Dizin Fuzzing', 'name_en': 'Web Security & Fuzzing', 'icon': 'language', 'color': '#f59e0b'},
    'services': {'id': 'services', 'name': 'Ağ Servisleri İstismarı', 'name_en': 'Network Services Exploitation', 'icon': 'router', 'color': '#a855f7'},
    'ad': {'id': 'ad', 'name': 'Active Directory & Kerberos', 'name_en': 'Active Directory & Kerberos', 'icon': 'domain', 'color': '#6366f1'},
    'shells_pivoting': {'id': 'shells_pivoting', 'name': 'Reverse Shell & Tünelleme', 'name_en': 'Reverse Shells & Pivoting', 'icon': 'terminal', 'color': '#10b981'},
    'privesc': {'id': 'privesc', 'name': 'Yetki Yükseltme (PrivEsc)', 'name_en': 'Privilege Escalation', 'icon': 'arrow_upward', 'color': '#ef4444'},
    'auth_cracking': {'id': 'auth_cracking', 'name': 'Kimlik & Parola Kırma', 'name_en': 'Auth & Password Cracking', 'icon': 'lock_open', 'color': '#ec4899'},
    'cloud': {'id': 'cloud', 'name': 'Bulut & Konteyner', 'name_en': 'Cloud & Containers', 'icon': 'cloud', 'color': '#06b6d4'},
}

def clean_command_line(line: str) -> str:
    """Komut satırındaki shell prompt ve fazlalıkları temizler."""
    line = line.strip()
    # Shell promptlarını kaldır
    line = re.sub(r'^(?:root@[\w\-]+:.*?#|\$|#|PS [C-Z]:\\.*?>|>)\s+', '', line)
    # GitHub Secret Scanning koruması: Örnek dummy bulut token'larını güvenli yer tutuculara çevir
    line = re.sub(r'1//0[a-zA-Z0-9_\-]+', '{{google_refresh_token}}', line)
    line = re.sub(r'ya29\.[a-zA-Z0-9_\-]+', '{{google_oauth_token}}', line)
    line = re.sub(r'AIza[0-9A-Za-z-_]{35}', '{{google_api_key}}', line)
    line = re.sub(r'AKIA[0-9A-Z]{16}', '{{aws_access_key}}', line)
    # Satır sonu ters slaşları birleştirilmişse temizle
    line = line.rstrip('\\').strip()
    return line

def parameterize(cmd: str):
    """Komut içindeki sabit değerleri evrensel şablon yer tutucularına dönüştürür."""
    template = cmd
    variables = set()

    # 1. URL'ler
    urls = re.findall(r'https?://[^\s\'"<>]+', template)
    for u in urls:
        template = template.replace(u, '{{target_url}}')
        variables.add('TARGET_URL')

    # 2. IP Adresleri
    for ip_pat in IP_PATTERNS:
        matches = re.findall(ip_pat, template)
        for m in matches:
            if m in ['127.0.0.1']:
                template = template.replace(m, '{{lhost}}')
                variables.add('LHOST')
            else:
                template = template.replace(m, '{{target_ip}}')
                variables.add('TARGET_IP')

    # 3. Domain
    for d_pat in DOMAIN_PATTERNS:
        matches = re.findall(d_pat, template, flags=re.IGNORECASE)
        for m in matches:
            template = template.replace(m, '{{domain}}')
            variables.add('DOMAIN')

    # 4. Portlar
    port_matches = re.findall(r'(?:-p\s*|--port\s*|:)(\d{2,5})\b', template)
    for p in port_matches:
        if p in ['4444', '9001', '1337', '8888']:
            template = re.sub(rf'\b{p}\b', '{{lport}}', template)
            variables.add('LPORT')
        elif p in ['80', '443', '8080', '8443', '445', '139', '389', '636', '88', '21', '22', '23', '25', '1433', '3306', '5432', '3389', '5985']:
            template = re.sub(rf'\b{p}\b', '{{port}}', template)
            variables.add('PORT')

    # 5. Wordlist yolları
    if '/usr/share/' in template or 'wordlist' in template.lower() or 'rockyou' in template.lower():
        template = re.sub(r'/[^\s\'"]*(?:wordlists?|rockyou|SecLists|dirb|common)[^\s\'"]*', '{{wordlist}}', template)
        variables.add('WORDLIST')

    return template, sorted(list(variables))

def detect_tool(line: str):
    """Komut satırındaki ana siber güvenlik aracını tespit eder."""
    tokens = line.split()
    if not tokens:
        return None
    first = tokens[0].lower().strip('./')
    
    # sudo / proxychains vb. arkasındaki asıl komut
    if first in ['sudo', 'proxychains', 'proxychains4', 'doas', 'time', 'nohup', 'exec'] and len(tokens) > 1:
        first = tokens[1].lower().strip('./')

    if first in TOOL_DEFINITIONS:
        return first

    # İkincil eşleme
    for tool_name in TOOL_DEFINITIONS.keys():
        if re.search(rf'\b{re.escape(tool_name)}(?:\.exe|\.py|\.sh)?\b', line, re.IGNORECASE):
            return tool_name

    # Özel komut kalıpları
    if any(k in line.lower() for k in ['bash -i', 'nc -e', 'rm /tmp/f;mkfifo', 'python -c "import socket', 'python3 -c "import socket']):
        return 'nc'
    if any(k in line.lower() for k in ['get-domain', 'invoke-', 'find-domain']):
        return 'powerview'
    if 'mimikatz' in line.lower():
        return 'mimikatz'
    if 'rubeus' in line.lower():
        return 'rubeus'
    if 'bloodhound' in line.lower() or 'sharphound' in line.lower():
        return 'bloodhound'

    return None

def extract_commands_from_file(filepath: Path, lang: str):
    """Bir Markdown dosyasından geçerli komut bloklarını çıkarır."""
    commands = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception:
        return commands

    if lang == 'cloud':
        try:
            rel_path = str(filepath.relative_to(BASE_DIR / 'sources' / 'hacktricks-cloud' / 'src'))
        except ValueError:
            rel_path = str(filepath.relative_to(BASE_DIR / 'sources' / 'hacktricks-cloud-tr' / 'src'))
    else:
        try:
            rel_path = str(filepath.relative_to(BASE_DIR / 'sources' / f'hacktricks-{lang}' / 'src'))
        except ValueError:
            rel_path = str(filepath.relative_to(BASE_DIR / 'sources' / f'hacktricks-{lang}'))
            if rel_path.startswith('src/'):
                rel_path = rel_path[4:]
    
    # Baştaki src/ kalıntısı varsa temizle (articles.json ile tam uyum)
    if rel_path.startswith('src/'):
        rel_path = rel_path[4:]
    
    # Dosya başlığı bul
    title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
    doc_title = title_match.group(1).strip() if title_match else filepath.stem.replace('-', ' ').title()

    # Markdown kod bloklarını bul
    code_blocks = re.finditer(r'```([a-zA-Z0-9_\-\+]*)\s*\n(.*?)```', content, re.DOTALL)
    
    for block in code_blocks:
        lang_tag = block.group(1).lower().strip()
        code_text = block.group(2).strip()

        # Çıktı bloklarını veya konfigürasyon dosyalarını (json, yaml, xml, txt çıktısı vb.) atla
        if lang_tag in ['json', 'yaml', 'yml', 'xml', 'toml', 'ini', 'output', 'txt', 'log', 'markdown', 'md']:
            continue

        lines = code_text.split('\n')
        curr_cmd = []

        for line in lines:
            line_str = clean_command_line(line)
            if not line_str or line_str.startswith('#') or line_str.startswith('//'):
                continue
            
            # Satır sonu birleştirme (\) kontrolü
            if line.rstrip().endswith('\\'):
                curr_cmd.append(line_str)
                continue
            else:
                if curr_cmd:
                    curr_cmd.append(line_str)
                    full_cmd = " ".join(curr_cmd)
                    curr_cmd = []
                else:
                    full_cmd = line_str

            tool = detect_tool(full_cmd)
            if not tool:
                continue

            # Sahte veya açıklama metinlerini (İngilizce cümleleri) filtrele
            tokens = full_cmd.split()
            first = tokens[0].lower().strip('./') if tokens else ''
            if first in ['sudo', 'proxychains', 'proxychains4', 'doas'] and len(tokens) > 1:
                first = tokens[1].lower().strip('./')
            if not (first == tool or first.startswith(tool) or tool.startswith(first)):
                if not re.search(r'[-/\\|>\$\"\']', full_cmd):
                    continue
                if re.match(r'^(?:run|use|install|in order to|you can|execute|start|please|note|the|this|to)\b', full_cmd, re.IGNORECASE):
                    continue

            tool_meta = TOOL_DEFINITIONS.get(tool, {
                'cat': 'recon', 'plat': 'Linux CLI', 'opsec': 'noisy', 'pillar': 'red'
            })

            # Parametrelendir
            template, variables = parameterize(full_cmd)

            # Başlık / Açıklama üret
            title = f"{tool.upper()} - {doc_title}"
            if len(title) > 85:
                title = title[:82] + '...'

            # Benzersiz kimlik
            cmd_id = hashlib.sha1(f"{tool}:{full_cmd}".encode('utf-8')).hexdigest()[:12]

            commands.append({
                'id': cmd_id,
                'tool': tool,
                'category': tool_meta['cat'],
                'platform': tool_meta['plat'],
                'pillar': tool_meta['pillar'],
                'opsec': tool_meta['opsec'],
                'title': title,
                'raw_command': full_cmd,
                'template': template,
                'variables': variables,
                'doc_title': doc_title,
                'doc_path': rel_path,
                'lang': lang
            })

    return commands

def main():
    print("=== HackTricks Evrensel Komut & Cephanelik Çıkarıcı Başlatılıyor ===")
    
    all_commands = {}
    
    # 1. EN Dokümanları
    en_dir = BASE_DIR / 'sources' / 'hacktricks-en' / 'src'
    if not en_dir.exists():
        en_dir = BASE_DIR / 'sources' / 'hacktricks-en'
    if en_dir.exists():
        print(f"[+] 'EN' dokümanları taranıyor ({en_dir})...")
        for p in en_dir.rglob('*.md'):
            for cmd in extract_commands_from_file(p, 'en'):
                key = cmd['template']
                if key not in all_commands:
                    all_commands[key] = cmd

    # 2. HackTricks Cloud Dokümanları (EN)
    cloud_dir = BASE_DIR / 'sources' / 'hacktricks-cloud' / 'src'
    if cloud_dir.exists():
        print(f"[+] 'CLOUD (EN)' dokümanları taranıyor ({cloud_dir})...")
        for p in cloud_dir.rglob('*.md'):
            for cmd in extract_commands_from_file(p, 'cloud'):
                key = cmd['template']
                if key not in all_commands:
                    all_commands[key] = cmd

    # 2.5 HackTricks Cloud Dokümanları (TR)
    cloud_tr_dir = BASE_DIR / 'sources' / 'hacktricks-cloud-tr' / 'src'
    if cloud_tr_dir.exists():
        print(f"[+] 'CLOUD (TR)' dokümanları taranıyor ({cloud_tr_dir})...")
        for p in cloud_tr_dir.rglob('*.md'):
            for cmd in extract_commands_from_file(p, 'cloud'):
                key = cmd['template']
                if key not in all_commands:
                    all_commands[key] = cmd

    # 3. TR Dokümanları
    tr_dir = BASE_DIR / 'sources' / 'hacktricks-tr' / 'src'
    if not tr_dir.exists():
        tr_dir = BASE_DIR / 'sources' / 'hacktricks-tr'
    if tr_dir.exists():
        print(f"[+] 'TR' dokümanları taranıyor ({tr_dir})...")
        for p in tr_dir.rglob('*.md'):
            for cmd in extract_commands_from_file(p, 'tr'):
                key = cmd['template']
                if key not in all_commands:
                    all_commands[key] = cmd

    final_command_list = list(all_commands.values())

    # Kategori istatistikleri
    cat_counts = {}
    plat_counts = {}
    for c in final_command_list:
        cat_counts[c['category']] = cat_counts.get(c['category'], 0) + 1
        plat_counts[c['platform']] = plat_counts.get(c['platform'], 0) + 1

    print(f"\n[✓] Toplam {len(final_command_list)} adet benzersiz operasyonel komut çıkarıldı!")
    print("    Kategori Dağılımı:")
    for cat_id, meta in CATEGORIES_META.items():
        cnt = cat_counts.get(cat_id, 0)
        print(f"      • {meta['name']}: {cnt} komut")

    print("\n    Platform Dağılımı:")
    for plat, cnt in plat_counts.items():
        print(f"      • {plat}: {cnt} komut")

    payload = {
        'version': '2.0.0',
        'total_commands': len(final_command_list),
        'categories': CATEGORIES_META,
        'commands': final_command_list
    }

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    print(f"\n[✓] Başarıyla kaydedildi: {OUTPUT_FILE}")

if __name__ == '__main__':
    main()
