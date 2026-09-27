#!/bin/bash
# =============================================================
# 04_iniciar_snort.sh
# Inicia Snort (2 o 3) con las reglas del laboratorio.
# Compatible con Kali Linux 2022 y 2023+.
# =============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Rutas ─────────────────────────────────────────────────────
LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RULES_FILE="$LAB_DIR/snort_rules/lab_ransomware.rules"
SNORT_LUA="$LAB_DIR/snort_rules/lab_snort.lua"
LOG_DIR="/var/log/snort"

# ── Detectar interfaz de red ──────────────────────────────────
# EXPLICACIÓN TÉCNICA:
#   En un lab de una sola VM, tanto el servidor (01_servidor_malicioso.sh)
#   como el cliente (wget / simulador) corren en la MISMA IP (p.ej. 192.168.1.14).
#   En Linux, el tráfico de una IP a sí misma se enruta a través de la
#   interfaz LOOPBACK (lo), no por la interfaz física (eth0/wlan0).
#   Por eso Snort debe escuchar en 'lo', no en eth0.
#
#   Para un lab de dos VMs (Snort en VM1, víctima en VM2), cambia la
#   interfaz con: export LAB_IFACE=eth0 (antes de ejecutar este script).
#
IFACE="${LAB_IFACE:-lo}"
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

# ── Verificar archivos del lab ────────────────────────────────
if [ ! -f "$RULES_FILE" ]; then
  echo -e "${RED}[!] No se encontró: $RULES_FILE${NC}"; exit 1
fi

# ── Crear carpeta de logs ─────────────────────────────────────
sudo mkdir -p "$LOG_DIR"

echo -e "${YELLOW}[*] Snort arrancando... (Ctrl+C para detener)${NC}"
echo "─────────────────────────────────────────────────────"

if [ "$SNORT_MAJOR" = "3" ]; then
  # ── SNORT 3 ───────────────────────────────────────────────
  # Usamos lab_snort.lua propio del lab en lugar del snort.lua del
  # sistema. Razones:
  #   1. El snort.lua del sistema tiene binders y HTTP inspector que
  #      interfieren con las reglas alert tcp del lab.
  #   2. lab_snort.lua es mínimo y solo carga lo que el lab necesita.
  #
  # -k none: bypasa validación de checksums TCP. El tráfico capturado
  #   en loopback (mismo IP origen/destino) tiene checksums inválidos
  #   porque el kernel usa TCP checksum offloading en la interfaz lo.
  #   Sin -k none Snort descarta todos los paquetes antes de evaluarlos.

  # Copiar las reglas al directorio del sistema para que lab_snort.lua
  # pueda leerlas (Snort 3 necesita ruta absoluta o relativa al CWD).
  sudo cp "$RULES_FILE" /etc/snort/rules/lab_ransomware.rules

  echo -e "  Config   : ${GREEN}$SNORT_LUA${NC}"
  echo -e "  ${CYAN}Modo Snort 3 → alertas en ${LOG_DIR}/alert_fast.txt${NC}"
  echo

  sudo LOG_DIR="$LOG_DIR" snort \
    -c "$SNORT_LUA" \
    -i "$IFACE" \
    -A alert_fast \
    -l "$LOG_DIR" \
    -k none \
    -q 2>&1

else
  # ── SNORT 2 ───────────────────────────────────────────────
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
