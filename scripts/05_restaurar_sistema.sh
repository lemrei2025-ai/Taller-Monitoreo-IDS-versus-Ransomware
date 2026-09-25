#!/bin/bash
# =============================================================
# 05_restaurar_sistema.sh
# Revierte todos los cambios del simulador IOC:
#  - Renombra los .locked de vuelta a .txt
#  - Elimina la nota de rescate ficticia
#  - Elimina la regla iptables del reto 3
# =============================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

# ── Rutas relativas al repositorio (no depende de $HOME) ─────
LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX="$LAB_DIR/data/victima_documentos"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║     🔄  Restaurando sistema del LAB  🔄     ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Sandbox: ${CYAN}$SANDBOX${NC}"
echo

# ── 1. Restaurar archivos .locked ────────────────────────────
echo -e "${BOLD}[1/3] Restaurando archivos señuelo...${NC}"
RESTORED=0
for f in "$SANDBOX"/*.locked; do
  [ -f "$f" ] || continue
  orig="${f%.locked}"
  mv "$f" "$orig"
  echo -e "  ${GREEN}✔${NC} $(basename "$orig")"
  ((RESTORED++))
done
[ "$RESTORED" -eq 0 ] && echo "  (ningún archivo .locked encontrado)" \
                      || echo "  Total restaurados: $RESTORED"

# ── 2. Eliminar nota de rescate ───────────────────────────────
echo -e "\n${BOLD}[2/3] Eliminando nota de rescate...${NC}"
NOTA="$SANDBOX/LEEME_RESCATE.txt"
if [ -f "$NOTA" ]; then
  rm "$NOTA"
  echo -e "  ${GREEN}✔${NC} Nota eliminada"
else
  echo "  (no existe nota de rescate)"
fi

# ── 3. Limpiar reglas iptables del laboratorio ────────────────
echo -e "\n${BOLD}[3/3] Limpiando reglas iptables del LAB...${NC}"
sudo iptables -D FORWARD -p tcp --dport 8080 -j DROP 2>/dev/null \
  && echo -e "  ${GREEN}✔${NC} Regla puerto 8080 eliminada" \
  || echo "  (no había regla en puerto 8080)"
sudo iptables -D FORWARD -p tcp --dport 4444 -j DROP 2>/dev/null \
  && echo -e "  ${GREEN}✔${NC} Regla puerto 4444 eliminada" \
  || echo "  (no había regla en puerto 4444)"

echo -e "\n${GREEN}${BOLD}✅ Sistema restaurado. El laboratorio está limpio.${NC}"
echo -e "   Para repetir desde el inicio: bash scripts/00b_preparar_lab.sh"
echo
