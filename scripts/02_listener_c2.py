#!/usr/bin/env python3
"""
02_listener_c2.py
Laboratorio: IDS y Detección de Ransomware en Kali Linux

Panel C2 de PRÁCTICA — registra beacons de entrada y responde OK.
NO envía comandos, NO ejecuta código, NO recibe archivos.
Es únicamente el blanco de red que Snort debe detectar.

Incluye un kill switch (como el de WannaCry): si existe el archivo
killswitch.flag en el directorio actual, la ruta /killswitch
responde HTTP 200 y el simulador IOC se detiene por sí solo.

Ejecutar (terminal 2, VM ATACANTE o Kali):
    python3 02_listener_c2.py [--port 4444]
"""

import os
import sys
import argparse
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

KILL_FILE = "killswitch.flag"
BEACONS_LOG: list[str] = []

ANSI = {
    "cyan": "\033[0;36m", "green": "\033[0;32m",
    "yellow": "\033[1;33m", "red": "\033[0;31m",
    "bold": "\033[1m", "nc": "\033[0m"
}


def col(color: str, text: str) -> str:
    return f"{ANSI[color]}{text}{ANSI['nc']}"


class C2Handler(BaseHTTPRequestHandler):
    server_version = "LabC2/1.0"

    def do_GET(self):
        ts = datetime.now().strftime("%H:%M:%S")
        ip = self.client_address[0]
        ua = self.headers.get("User-Agent", "-")
        entry = f"[{ts}] {ip} → {self.path}  UA={ua}"
        print(col("green", entry))
        BEACONS_LOG.append(entry)

        if self.path.startswith("/killswitch"):
            code = 200 if os.path.exists(KILL_FILE) else 404
            self.send_response(code)
            self.end_headers()
            msg = "ACTIVO 🛑" if code == 200 else "INACTIVO"
            print(col("yellow", f"  ↳ Kill switch: {msg}"))
            return

        if self.path.startswith("/beacon"):
            print(col("yellow", f"  ↳ 🔔 BEACON RECIBIDO  →  IOC activo en {ip}"))

        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"OK\n")

    def log_message(self, *_):
        pass  # suprimimos el log por defecto


def main():
    parser = argparse.ArgumentParser(description="Panel C2 de práctica")
    parser.add_argument("--port", type=int, default=4444)
    args = parser.parse_args()

    print(col("cyan", col("bold",
        "\n╔══════════════════════════════════════════╗\n"
        "║   🎯  Panel C2 de Práctica (solo logs)  ║\n"
        "╚══════════════════════════════════════════╝")))
    print(f"  Escuchando en 0.0.0.0:{args.port}")
    print(f"  Kill switch: touch {KILL_FILE}\n")
    print("─" * 46)

    try:
        HTTPServer(("0.0.0.0", args.port), C2Handler).serve_forever()
    except KeyboardInterrupt:
        print(f"\n\n{col('yellow','Total beacons recibidos:')} {len(BEACONS_LOG)}")
        print(col("yellow", "Servidor detenido. ¿Cuántas alertas generó Snort?"))
        sys.exit(0)


if __name__ == "__main__":
    main()
