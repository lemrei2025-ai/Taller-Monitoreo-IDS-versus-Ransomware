#!/bin/bash
# =============================================================
# 04_iniciar_snort.sh
# Inicia Snort en modo IDS con las reglas personalizadas del lab.
# Ejecutar en la VM ANALISTA (o en la Kali principal, terminal 4)
# =============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

RULES_FILE="$(cd "$(dirname "$0")/.." && pwd)/snort_rules/lab_ransomware.rules"
LOG_DIR="/var/log/snort"
ALERT_FILE="$LOG_DIR/alert"

# ── Detectar interfaz de red ──────────────────────────────────
IFACE=$(ip -brief link show | grep -v '^lo' | awk '{print $1}' | head -1)
if [ -z "$IFACE" ]; then
  echo -e "${RED}[!] No se encontró interfaz de red activa.${NC}"
  exit 1
fi

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║       🔍  Iniciando Snort IDS  🔍            ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Interfaz : ${GREEN}$IFACE${NC}"
echo -e "  Reglas   : ${GREEN}$RULES_FILE${NC}"
echo -e "  Alertas  : ${GREEN}$ALERT_FILE${NC}"
echo

# ── Verificar que existan las reglas ─────────────────────────
if [ ! -f "$RULES_FILE" ]; then
  echo -e "${RED}[!] No se encontró el archivo de reglas: $RULES_FILE${NC}"
  exit 1
fi

# ── Crear carpeta de log si no existe ────────────────────────
sudo mkdir -p "$LOG_DIR"
sudo touch "$ALERT_FILE"

echo -e "${YELLOW}[*] Snort arrancando... (Ctrl+C para detener)${NC}"
echo "─────────────────────────────────────────────────────"
echo

# Modo IDS: captura paquetes, aplica reglas, escribe alertas
sudo snort \
  -i "$IFACE" \
  -A fast \
  -l "$LOG_DIR" \
  -c /etc/snort/snort.conf \
  --rule-path "$(dirname "$RULES_FILE")" \
  -R "$RULES_FILE" \
  -q

# ── Nota: si snort no acepta --rule-path, usa la variante: ───
# sudo snort -i "$IFACE" -A fast -l "$LOG_DIR" -c /etc/snort/snort.conf \
#   --daq-dir /usr/lib/daq -R "$RULES_FILE" -q
