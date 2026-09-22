#!/bin/bash
# =============================================================
# 00a_instalar_paquetes.sh
# PASO PREVIO — Instalar herramientas del laboratorio
# -------------------------------------------------------------
# ⚠  Ejecutar con el adaptador de red en modo NAT (necesita
#    Internet para descargar paquetes con apt).
#
# Una vez terminado, cambia la VM a Host-Only y ejecuta:
#    sudo bash scripts/00b_preparar_lab.sh
# =============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   🛡️  Laboratorio IDS + Ransomware — Kali Linux      ║"
echo "║       Paso 0-A: Instalación de herramientas          ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Verificar Internet ────────────────────────────────────────
echo -e "${BOLD}[1/2] Verificando conexión a Internet...${NC}"
if ! ping -c 1 -W 4 8.8.8.8 >/dev/null 2>&1; then
  echo -e "${RED}${BOLD}"
  echo "  ✘  Sin acceso a Internet."
  echo -e "${NC}"
  echo -e "${YELLOW}Este script requiere que el adaptador de red esté en modo NAT."
  echo
  echo "  En VirtualBox:"
  echo "    1. Apaga la VM (o usa Dispositivos → Adaptadores de red)"
  echo "    2. Cambia Adaptador 1 a: NAT"
  echo "    3. Vuelve a ejecutar este script"
  echo
  echo "  Alternativa — dos adaptadores (recomendada para el lab):"
  echo "    • Adaptador 1: NAT      ← Internet para instalar paquetes"
  echo "    • Adaptador 2: Host-Only ← red aislada para el tráfico del lab"
  echo -e "${NC}"
  exit 1
fi
echo -e "  ${GREEN}✔${NC} Hay Internet (modo NAT activo)"

# ── Instalar paquetes ─────────────────────────────────────────
echo
echo -e "${BOLD}[2/2] Instalando herramientas...${NC}"
PKGS=(snort python3 tcpdump net-tools iptables)
MISSING=()

for pkg in "${PKGS[@]}"; do
  if command -v "$pkg" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✔${NC} $pkg (ya instalado)"
  else
    MISSING+=("$pkg")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "  ${YELLOW}Instalando: ${MISSING[*]}${NC}"
  apt update -qq 2>&1 | tail -1
  DEBIAN_FRONTEND=noninteractive apt install -y "${MISSING[@]}"
  echo -e "  ${GREEN}✔${NC} Paquetes instalados correctamente"
else
  echo -e "  ${GREEN}✔${NC} Todos los paquetes ya estaban instalados"
fi

echo
echo -e "${GREEN}${BOLD}✅ Herramientas listas.${NC}"
echo
echo -e "${YELLOW}${BOLD}➡  SIGUIENTE PASO:${NC}"
echo -e "${YELLOW}   1. Cambia la VM a red Host-Only en VirtualBox"
echo -e "   2. Ejecuta: sudo bash scripts/00b_preparar_lab.sh${NC}"
echo
