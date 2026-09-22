#!/bin/bash
# =============================================================
# 04b_monitorear_alertas.sh
# Monitor de alertas Snort en tiempo real.
# Compatible con Snort 2 y Snort 3.
# Abrir en una terminal separada mientras Snort corre.
# =============================================================

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

LOG_DIR="/var/log/snort"

# ── Detectar qué archivo de alertas usa esta versión ─────────
SNORT_MAJOR=$(snort --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)

if [ "$SNORT_MAJOR" = "3" ]; then
  ALERT_FILE="$LOG_DIR/alert_fast.txt"
else
  ALERT_FILE="$LOG_DIR/alert"
fi

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║      📊  Monitor de Alertas Snort  📊        ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Snort versión : ${GREEN}${SNORT_MAJOR}.x${NC}"
echo -e "  Archivo       : ${GREEN}$ALERT_FILE${NC}"
echo -e "  Estado        : esperando alertas... (Ctrl+C para salir)"
echo "─────────────────────────────────────────────────────"
echo

# ── Crear el archivo si aún no existe ────────────────────────
sudo mkdir -p "$LOG_DIR"
sudo touch "$ALERT_FILE"

# ── Monitorear con colores ────────────────────────────────────
sudo tail -f "$ALERT_FILE" | while IFS= read -r line; do
  if echo "$line" | grep -qi "EICAR\|Malware\|Factura"; then
    echo -e "${RED}${BOLD}$line${NC}"
  elif echo "$line" | grep -qi "Beacon\|C2\|killswitch\|kill switch"; then
    echo -e "${YELLOW}${BOLD}$line${NC}"
  elif echo "$line" | grep -qi "PowerShell\|ps1"; then
    echo -e "${RED}$line${NC}"
  elif echo "$line" | grep -qi "4444\|8080"; then
    echo -e "${YELLOW}$line${NC}"
  elif echo "$line" | grep -qi "RETO4\|MiRansomware"; then
    echo -e "${CYAN}${BOLD}$line${NC}"
  elif echo "$line" | grep -qi "BONUS\|rescate"; then
    echo -e "${GREEN}${BOLD}$line${NC}"
  else
    echo -e "${CYAN}$line${NC}"
  fi
done
