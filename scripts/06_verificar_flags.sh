#!/bin/bash
# =============================================================
# 06_verificar_flags.sh
# Sistema de puntuación CTF del laboratorio.
# Comprueba automáticamente los logros de cada reto.
# Compatible con Snort 2 y Snort 3.
# =============================================================

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Rutas relativas al repositorio (no depende de $HOME) ─────
LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX="$LAB_DIR/data/victima_documentos"

# ── Detectar archivo de alertas según versión de Snort ───────
SNORT_MAJOR=$(snort --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
if [ "$SNORT_MAJOR" = "3" ]; then
  ALERT_FILE="/var/log/snort/alert_fast.txt"
else
  ALERT_FILE="/var/log/snort/alert"
fi

puntos=0
total=5

banner() {
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║         🏆  Verificación de Retos CTF  🏆            ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "  Lab dir    : ${CYAN}$LAB_DIR${NC}"
  echo -e "  Sandbox    : ${CYAN}$SANDBOX${NC}"
  echo -e "  Alert file : ${CYAN}$ALERT_FILE${NC}  (Snort ${SNORT_MAJOR}.x)"
  echo
}

ok()  { echo -e "  ${GREEN}✅ [+20 pts]${NC} $1"; ((puntos+=20)); }
fail(){ echo -e "  ${RED}❌ [+0  pts]${NC} $1"; }
warn(){ echo -e "  ${YELLOW}⚠  ${NC} $1"; }

banner

# ── RETO 1: Snort ha generado al menos 1 alerta ──────────────
echo -e "${BOLD}Reto 1 — Snort en marcha y detectando${NC}"
if sudo test -f "$ALERT_FILE" && sudo test -s "$ALERT_FILE" 2>/dev/null; then
  NALERTS=$(sudo wc -l < "$ALERT_FILE" 2>/dev/null || echo 0)
  ok "Snort generó alertas ($NALERTS líneas en $(basename $ALERT_FILE))"
else
  fail "No se encontraron alertas. ¿Está Snort corriendo?"
  warn "Log esperado: $ALERT_FILE"
fi

# ── RETO 2: Archivos .locked existen (simulador corrió) ──────
echo -e "\n${BOLD}Reto 2 — Simulador IOC ejecutado${NC}"
NLOCKED=$(ls "$SANDBOX"/*.locked 2>/dev/null | wc -l)
if [ "$NLOCKED" -gt 0 ]; then
  ok "Se encontraron $NLOCKED archivos .locked en data/victima_documentos/"
else
  fail "No hay archivos .locked. ¿Ejecutaste scripts/03_simulador_ioc.py?"
fi

# ── RETO 3: Regla iptables que bloquea el C2 ─────────────────
echo -e "\n${BOLD}Reto 3 — Firewall bloqueando C2 (puerto 4444)${NC}"
if sudo iptables -L FORWARD -v -n 2>/dev/null | grep -q "dpt:4444"; then
  ok "Regla iptables DROP en puerto 4444 confirmada"
else
  fail "No se encontró regla iptables para puerto 4444"
  warn "Pista: sudo iptables -I FORWARD -p tcp --dport 4444 -j DROP"
fi

# ── RETO 4: Kill switch activado ─────────────────────────────
echo -e "\n${BOLD}Reto 4 — Kill switch activado${NC}"
if [ -f "$LAB_DIR/killswitch.flag" ]; then
  ok "Archivo killswitch.flag encontrado"
else
  fail "Kill switch no activado"
  warn "Pista: touch $LAB_DIR/killswitch.flag"
fi

# ── RETO 5: Sistema restaurado ───────────────────────────────
echo -e "\n${BOLD}Reto 5 — Sistema restaurado${NC}"
NTXT=$(ls "$SANDBOX"/*.txt 2>/dev/null | grep -v LEEME | wc -l)
if [ "$NTXT" -ge 8 ] && [ "$NLOCKED" -eq 0 ]; then
  ok "Todos los documentos restaurados ($NTXT archivos)"
else
  fail "Sistema no restaurado completamente"
  warn "Pista: bash scripts/05_restaurar_sistema.sh"
fi

# ── RESULTADO FINAL ──────────────────────────────────────────
echo
echo "═══════════════════════════════════════════════════════"
PCT=$((puntos * 100 / (total * 20)))
echo -e "  ${BOLD}Puntuación: ${CYAN}$puntos / $((total*20)) puntos${NC}  ($PCT%)"
echo

if   [ $puntos -eq $((total*20)) ]; then
  echo -e "  ${GREEN}${BOLD}🥇 EXCELENTE — Insignia: 'Cazador de Amenazas' 🛡️${NC}"
elif [ $puntos -ge 60 ]; then
  echo -e "  ${YELLOW}${BOLD}🥈 MUY BIEN — Insignia: 'Analista SOC Jr.' 🔍${NC}"
elif [ $puntos -ge 40 ]; then
  echo -e "  ${YELLOW}🥉 BIEN — Sigue practicando, vas por buen camino.${NC}"
else
  echo -e "  ${RED}📚 Revisa la guía del estudiante y vuelve a intentarlo.${NC}"
fi
echo "═══════════════════════════════════════════════════════"
echo
