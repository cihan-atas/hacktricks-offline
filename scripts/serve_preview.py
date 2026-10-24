#!/usr/bin/env python3
"""
HackTricks Offline - Yerel Test Sunucusu
Bu script, Android APK içine gömülen www/ arayüzünü tarayıcınızda test etmenizi sağlar.
"""
import http.server
import socketserver
import os
import sys

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "android", "app", "src", "main", "assets", "www")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

if __name__ == "__main__":
    if not os.path.exists(DIRECTORY):
        print(f"[!] Hata: {DIRECTORY} klasörü bulunamadı.")
        print("[!] Lütfen önce './scripts/fetch_and_build.sh' betiğini çalıştırın.")
        sys.exit(1)

    print(f"[+] Sunucu başlatıldı: http://localhost:{PORT}")
    print(f"[+] Sunulan dizin: {DIRECTORY}")
    print("[+] Çıkış yapmak için Ctrl+C tuşlarına basın.")

    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nSunucu kapatıldı.")
