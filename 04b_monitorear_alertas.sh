#!/bin/bash
# =============================================================
# 04b_monitorear_alertas.sh
# Muestra en tiempo real las alertas de Snort con colores.
# Abrir en una terminal separada mientras Snort corre.
# =============================================================

ALERT_FILE="/var/log/snort/alert"
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║      📊  Monitor de Alertas Snort  📊        ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}  Archivo: $ALERT_FILE"
echo -e "  Esperando alertas... (Ctrl+C para salir)\n"
echo "─────────────────────────────────────────────────────"

sudo tail -f "$ALERT_FILE" | while IFS= read -r line; do
  # Colorear por tipo de alerta
  if echo "$line" | grep -qi "EICAR\|Malware\|Download"; then
    echo -e "${RED}${BOLD}$line${NC}"
  elif echo "$line" | grep -qi "Beacon\|C2\|Ransomware"; then
    echo -e "${YELLOW}${BOLD}$line${NC}"
  elif echo "$line" | grep -qi "PowerShell\|dropper\|ps1"; then
    echo -e "${RED}$line${NC}"
  elif echo "$line" | grep -qi "Firewall\|DROP\|BLOCK"; then
    echo -e "${GREEN}$line${NC}"
  else
    echo -e "${CYAN}$line${NC}"
  fi
done
