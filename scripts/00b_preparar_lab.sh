#!/bin/bash
# =============================================================
# 00b_preparar_lab.sh
# SETUP DEL LABORATORIO — Crea carpetas y archivos señuelo
# -------------------------------------------------------------
# ✅ Funciona en modo Host-Only (sin Internet).
# ✅ No instala nada. Solo crea la carpeta de trabajo local.
# ✅ No usa $HOME — funciona igual con sudo o sin sudo.
#
# Ejecutar DESPUÉS de 00a_instalar_paquetes.sh
# =============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

# ── Rutas relativas al repositorio (no depende de $HOME) ─────
LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$LAB_DIR/data"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   🛡️  Laboratorio IDS + Ransomware — Kali Linux      ║"
echo "║       Paso 0-B: Preparar carpeta del laboratorio     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Verificar que las herramientas estén instaladas ───────────
echo -e "${BOLD}[1/3] Verificando herramientas...${NC}"
PKGS=(snort python3 tcpdump iptables)
ALL_OK=true
for pkg in "${PKGS[@]}"; do
  if command -v "$pkg" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✔${NC} $pkg"
  else
    echo -e "  ${RED}✘${NC} $pkg — falta. Ejecuta primero: sudo bash scripts/00a_instalar_paquetes.sh"
    ALL_OK=false
  fi
done
[ "$ALL_OK" = false ] && exit 1

# ── Detectar interfaz de red (para Snort) ────────────────────
echo
echo -e "${BOLD}[2/3] Detectando interfaz de red...${NC}"
IFACE=$(ip -brief link show | grep -v '^lo' | awk '$2=="UP"{print $1}' | head -1)
[ -z "$IFACE" ] && IFACE=$(ip -brief link show | grep -v '^lo' | awk '{print $1}' | head -1)
IP_LOCAL=$(ip -4 -brief addr show "$IFACE" 2>/dev/null | awk '{print $3}' | cut -d/ -f1)

if [ -z "$IFACE" ]; then
  echo -e "  ${RED}✘${NC} No se encontró interfaz de red activa."
  exit 1
fi
echo -e "  ${GREEN}✔${NC} Interfaz: ${BOLD}$IFACE${NC}  —  IP: ${BOLD}${IP_LOCAL:-sin IP asignada}${NC}"
echo
echo -e "  ${YELLOW}Guarda esta IP: úsala en los comandos wget y"
echo -e "  en el simulador IOC del Reto 2 y 3.${NC}"

# ── Crear carpetas y archivos señuelo ────────────────────────
echo
echo -e "${BOLD}[3/3] Creando carpeta de trabajo y archivos señuelo...${NC}"
mkdir -p "$DATA_DIR/victima_documentos"
mkdir -p "$DATA_DIR/capturas"
echo -e "  ${GREEN}✔${NC} $DATA_DIR/victima_documentos/"
echo -e "  ${GREEN}✔${NC} $DATA_DIR/capturas/"
echo

for i in $(seq 1 8); do
  FILE="$DATA_DIR/victima_documentos/documento_confidencial_$i.txt"
  # No sobreescribir si ya existe (permite repetir el lab)
  if [ ! -f "$FILE" ]; then
    cat > "$FILE" <<EOF
==================================================
DOCUMENTO SEÑUELO #$i  —  LABORATORIO IDS/RANSOMWARE
==================================================
Este archivo fue creado automáticamente con fines
educativos. No contiene datos reales.
Fecha: $(date)
EOF
    echo -e "  ${GREEN}✔${NC} documento_confidencial_$i.txt"
  else
    echo -e "  ${YELLOW}→${NC} documento_confidencial_$i.txt (ya existía)"
  fi
done

# ── Crear /var/log/snort si no existe ────────────────────────
sudo mkdir -p /var/log/snort
echo -e "  ${GREEN}✔${NC} /var/log/snort/"

# ── Resumen final ─────────────────────────────────────────────
echo
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗"
echo    "║  ✅  Laboratorio listo. Abre la guía del estudiante  ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}"
echo
echo -e "  Directorio del lab : ${CYAN}$LAB_DIR${NC}"
echo -e "  Archivos señuelo   : ${CYAN}$DATA_DIR/victima_documentos/${NC}"
echo -e "  Tu IP              : ${CYAN}${IP_LOCAL:-ver con 'ip a'}${NC}"
echo -e "  Guía               : ${CYAN}$LAB_DIR/docs/guia_estudiante.md${NC}"
echo
echo -e "${BOLD}Abre 4 terminales y sigue el orden de la guía:${NC}"
echo -e "  Terminal A → bash scripts/01_servidor_malicioso.sh"
echo -e "  Terminal B → sudo bash scripts/04_iniciar_snort.sh"
echo -e "  Terminal C → bash scripts/04b_monitorear_alertas.sh"
echo -e "  Terminal D → (comandos wget y simulador IOC)"
echo
