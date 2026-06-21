#!/usr/bin/env python3
# ============================================================
# NetVisionConnect — agent CEC local.
# Écoute sur 127.0.0.1:9888 et pilote la TV via HDMI-CEC quand le
# player (page web) appelle /on ou /off — déclenché par les boutons
# « Allumer / Éteindre l'écran » du dashboard NetVisionConnect.
# ============================================================
from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess


def cec(command):
    try:
        subprocess.run(
            "echo '%s' | cec-client -s -d 1" % command,
            shell=True, timeout=15,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    except Exception:
        pass


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/off'):
            cec('standby 0')
        elif self.path.startswith('/on'):
            cec('on 0')
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

    def log_message(self, *args):
        pass  # silencieux


if __name__ == '__main__':
    HTTPServer(('127.0.0.1', 9888), Handler).serve_forever()
