#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys

PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
DIRECTORY = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else 'dist/web')

class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Tarayıcı önbelleğini engelle (Canlı geliştirme ve anında güncelleme için)
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

if __name__ == '__main__':
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), NoCacheHandler) as httpd:
        print(f"[*] HackTricks Vault Web (No-Cache) başlatıldı: http://localhost:{PORT}")
        print(f"[*] Dizin: {DIRECTORY}")
        httpd.serve_forever()
