#!/bin/bash
# =============================================================
# 00_preparar_entorno.sh
# Laboratorio: IDS y Detección de Ransomware en Kali Linux
# -------------------------------------------------------------
# Verifica e instala las dependencias necesarias.
# Ejecutar como root o con sudo.
# =============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

banner() {
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║   🛡️  Laboratorio IDS + Ransomware (Simulado) 🛡️     ║"
  echo "║          Preparación del entorno - Kali Linux        ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

banner

# ─── ADVERTENCIA DE SEGURIDAD ────────────────────────────────
echo -e "${RED}${BOLD}⚠  ADVERTENCIA DE SEGURIDAD ⚠${NC}"
echo -e "${YELLOW}Este laboratorio DEBE ejecutarse en una red AISLADA:"
echo "  • VirtualBox: modo 'Host-Only' o 'Internal Network'"
echo "  • VMware:     modo 'Host-Only'  o 'LAN Segment'"
echo "  • NUNCA lo ejecutes conectado a una red corporativa"
echo -e "    o con adaptador en modo BRIDGE hacia Internet.${NC}"
echo
read -rp "¿Confirmas que estás en una red aislada? [s/N]: " confirm
[[ "$confirm" =~ ^[sS]$ ]] || { echo "Cancelado."; exit 1; }
echo

# ─── VERIFICAR HERRAMIENTAS ───────────────────────────────────
PKGS=(snort python3 tcpdump net-tools iptables)
MISSING=()

echo -e "${BOLD}[1/3] Verificando herramientas...${NC}"
for pkg in "${PKGS[@]}"; do
  if command -v "$pkg" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✔${NC} $pkg"
  else
    echo -e "  ${RED}✘${NC} $pkg (falta)"
    MISSING+=("$pkg")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo
  echo -e "${YELLOW}[*] Instalando: ${MISSING[*]}${NC}"
  apt update -qq
  apt install -y "${MISSING[@]}"
fi

# ─── CREAR CARPETA DEL LABORATORIO ───────────────────────────
echo
echo -e "${BOLD}[2/3] Creando carpeta de trabajo...${NC}"
LAB_DIR="$HOME/lab_ransom_ids"
mkdir -p "$LAB_DIR/victima_documentos"
mkdir -p "$LAB_DIR/capturas"
echo -e "  ${GREEN}✔${NC} Carpeta: $LAB_DIR"

# ─── GENERAR ARCHIVOS SEÑUELO ─────────────────────────────────
echo
echo -e "${BOLD}[3/3] Generando 8 archivos señuelo...${NC}"
for i in $(seq 1 8); do
  cat > "$LAB_DIR/victima_documentos/documento_confidencial_$i.txt" <<EOF
==================================================
DOCUMENTO SEÑUELO #$i  —  LABORATORIO IDS/RANSOMWARE
==================================================
Este archivo fue creado automáticamente con fines
educativos. No contiene datos reales.
Fecha: $(date)
EOF
  echo -e "  ${GREEN}✔${NC} documento_confidencial_$i.txt"
done

echo
echo -e "${GREEN}${BOLD}✅ Entorno listo. Sigue con el Reto 1 de la guía.${NC}"
echo -e "   Carpeta del laboratorio: ${CYAN}$LAB_DIR${NC}"
