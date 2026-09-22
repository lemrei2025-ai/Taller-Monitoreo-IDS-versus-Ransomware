#!/bin/bash
# =============================================================
# 00_preparar_entorno.sh
# Laboratorio: IDS y Detección de Ransomware en Kali Linux
# -------------------------------------------------------------
# Verifica e instala las dependencias necesarias.
# Ejecutar como root o con sudo ANTES de cambiar la red a Host-Only.
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

# ─── VERIFICAR CONECTIVIDAD A INTERNET ───────────────────────
echo -e "${BOLD}[0/3] Verificando conectividad a Internet...${NC}"

TIENE_INTERNET=false
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
  TIENE_INTERNET=true
  echo -e "  ${GREEN}✔${NC} Hay acceso a Internet (modo NAT activo)"
else
  echo -e "  ${YELLOW}⚠${NC}  Sin acceso a Internet (probablemente modo Host-Only)"
fi

# ─── VERIFICAR HERRAMIENTAS ───────────────────────────────────
echo
echo -e "${BOLD}[1/3] Verificando herramientas...${NC}"
PKGS=(snort python3 tcpdump net-tools iptables)
MISSING=()

for pkg in "${PKGS[@]}"; do
  if command -v "$pkg" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✔${NC} $pkg"
  else
    echo -e "  ${RED}✘${NC} $pkg (falta)"
    MISSING+=("$pkg")
  fi
done

# ─── INSTALAR SI HACEN FALTA ─────────────────────────────────
if [ ${#MISSING[@]} -gt 0 ]; then
  echo
  if [ "$TIENE_INTERNET" = false ]; then
    echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════════╗"
    echo      "║  ❌  Sin Internet: no se pueden instalar los paquetes    ║"
    echo      "╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Faltan: ${MISSING[*]}${NC}"
    echo
    echo -e "${BOLD}Tienes 3 opciones para resolver esto:${NC}"
    echo
    echo -e "${CYAN}Opción 1 (Recomendada) — Dos adaptadores en VirtualBox:${NC}"
    echo "  • Adaptador 1: NAT           ← para tener Internet"
    echo "  • Adaptador 2: Host-Only     ← para la red del lab"
    echo "  Así instalas paquetes por NAT y el tráfico del lab"
    echo "  queda aislado en la red Host-Only."
    echo
    echo -e "${CYAN}Opción 2 — Instalar ANTES de cambiar a Host-Only:${NC}"
    echo "  1. Cambia temporalmente a NAT en VirtualBox"
    echo "  2. Ejecuta: sudo bash scripts/00_preparar_entorno.sh"
    echo "  3. Vuelve a Host-Only cuando termine"
    echo
    echo -e "${CYAN}Opción 3 — Instalar manualmente (descarga externa):${NC}"
    echo "  Descarga los .deb en una máquina con Internet y"
    echo "  cópialos a la VM con una carpeta compartida:"
    echo "  sudo dpkg -i snort_*.deb tcpdump_*.deb net-tools_*.deb"
    echo
    echo -e "${BOLD}Una vez instalados los paquetes, vuelve a ejecutar este script.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}[*] Instalando paquetes faltantes: ${MISSING[*]}${NC}"
  apt update -qq 2>&1 | tail -1
  DEBIAN_FRONTEND=noninteractive apt install -y "${MISSING[@]}"
  echo -e "${GREEN}✔ Paquetes instalados.${NC}"

  # Recordatorio de aislar la red después
  echo
  echo -e "${YELLOW}${BOLD}💡 Ahora que los paquetes están instalados:${NC}"
  echo -e "${YELLOW}   Cambia la VM a red Host-Only en VirtualBox antes"
  echo -e "   de ejecutar los scripts del laboratorio.${NC}"

elif [ "$TIENE_INTERNET" = true ]; then
  echo
  echo -e "${YELLOW}${BOLD}💡 Consejo:${NC}"
  echo -e "${YELLOW}   Todas las herramientas ya están instaladas.${NC}"
  echo -e "${YELLOW}   Cuando vayas a correr el lab, cambia la VM a red${NC}"
  echo -e "${YELLOW}   Host-Only para aislar el tráfico simulado.${NC}"
fi

# ─── CREAR CARPETA DEL LABORATORIO ───────────────────────────
echo
echo -e "${BOLD}[2/3] Creando carpeta de trabajo...${NC}"
LAB_DIR="$HOME/lab_ransom_ids"
mkdir -p "$LAB_DIR/victima_documentos"
mkdir -p "$LAB_DIR/capturas"
echo -e "  ${GREEN}✔${NC} $LAB_DIR/victima_documentos/"
echo -e "  ${GREEN}✔${NC} $LAB_DIR/capturas/"

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
echo
