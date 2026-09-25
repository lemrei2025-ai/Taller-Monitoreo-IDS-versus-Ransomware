#!/bin/bash
# =============================================================
# 04_iniciar_snort.sh
# Inicia Snort (2 o 3) con las reglas del laboratorio.
# Compatible con Kali Linux 2022 y 2023+.
# =============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Rutas ─────────────────────────────────────────────────────
RULES_FILE="$(cd "$(dirname "$0")/.." && pwd)/snort_rules/lab_ransomware.rules"
LOG_DIR="/var/log/snort"

# ── Detectar interfaz de red ──────────────────────────────────
# Snort 3 en Linux NO soporta '-i any': falla con "No codec for data
# link type 113" (LINKTYPE_LINUX_SLL). Se usa la interfaz física real.
#
# Preferencia: interfaz UP con IP asignada → cualquier interfaz UP → primera no-lo
IFACE=$(ip -brief addr show | grep -v '^lo' | awk '$3 != "" && $2 == "UP" {print $1; exit}')
[ -z "$IFACE" ] && IFACE=$(ip -brief link show | grep -v '^lo' | awk '$2=="UP"{print $1; exit}')
[ -z "$IFACE" ] && IFACE=$(ip -brief link show | grep -v '^lo' | awk '{print $1; exit}')
IFACE_DISPLAY="$IFACE"

# ── Detectar versión de Snort ─────────────────────────────────
if ! command -v snort >/dev/null 2>&1; then
  echo -e "${RED}[!] Snort no está instalado."
  echo -e "    Ejecuta primero: sudo bash scripts/00a_instalar_paquetes.sh${NC}"
  exit 1
fi

SNORT_VER=$(snort --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
SNORT_MAJOR=$(echo "$SNORT_VER" | cut -d. -f1)

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║       🔍  Iniciando Snort IDS  🔍            ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Versión  : ${GREEN}Snort $SNORT_VER (v${SNORT_MAJOR}.x)${NC}"
echo -e "  Interfaz : ${GREEN}$IFACE_DISPLAY${NC}"
echo -e "  Reglas   : ${GREEN}$RULES_FILE${NC}"
echo -e "  Logs     : ${GREEN}$LOG_DIR${NC}"
echo

# ── Verificar archivo de reglas ───────────────────────────────
if [ ! -f "$RULES_FILE" ]; then
  echo -e "${RED}[!] No se encontró: $RULES_FILE${NC}"; exit 1
fi

# ── Crear carpeta de logs ─────────────────────────────────────
sudo mkdir -p "$LOG_DIR"

echo -e "${YELLOW}[*] Snort arrancando... (Ctrl+C para detener)${NC}"
echo "─────────────────────────────────────────────────────"

if [ "$SNORT_MAJOR" = "3" ]; then
  # ── SNORT 3 ───────────────────────────────────────────────
  # Escribe alertas en: /var/log/snort/alert_fast.txt
  echo -e "  ${CYAN}Modo Snort 3 → alertas en ${LOG_DIR}/alert_fast.txt${NC}"
  echo
  sudo snort \
    -i "$IFACE" \
    -R "$RULES_FILE" \
    -A alert_fast \
    -l "$LOG_DIR" \
    -q 2>&1

else
  # ── SNORT 2 ───────────────────────────────────────────────
  # Si no existe snort.conf, creamos uno mínimo temporal
  CONF="/etc/snort/snort.conf"
  if [ ! -f "$CONF" ]; then
    echo -e "${YELLOW}[*] snort.conf no encontrado. Creando configuración mínima...${NC}"
    sudo mkdir -p /etc/snort
    sudo tee "$CONF" > /dev/null <<'CONF_EOF'
# Configuración mínima para el laboratorio IDS
var HOME_NET any
var EXTERNAL_NET any
config quiet
CONF_EOF
    echo -e "  ${GREEN}✔${NC} /etc/snort/snort.conf creado"
  fi

  # Escribe alertas en: /var/log/snort/alert
  echo -e "  ${CYAN}Modo Snort 2 → alertas en ${LOG_DIR}/alert${NC}"
  echo
  sudo touch "$LOG_DIR/alert"
  sudo snort \
    -i "$IFACE" \
    -A fast \
    -l "$LOG_DIR" \
    -c "$CONF" \
    -R "$RULES_FILE" \
    -q 2>&1
fi
