-- =============================================================
-- lab_snort.lua — Configuración Snort 3 para el laboratorio IDS
-- =============================================================
-- Uso (el script 04_iniciar_snort.sh lo llama automáticamente):
--   sudo snort -c lab_snort.lua -i <iface> -A alert_fast \
--              -l /var/log/snort -k none -q
-- =============================================================
-- NOTAS TÉCNICAS:
--   • -k none es obligatorio: el tráfico capturado en loopback
--     tiene checksums TCP inválidos por offloading del kernel.
--   • Las reglas usan 'alert tcp content:' (sin HTTP inspector)
--     para que disparen en cualquier puerto sin binders ni AppID.
--   • ips.rules = [[ include ... ]] es la forma correcta de
--     cargar un archivo de reglas externo en Snort 3. El campo
--     ips.include es para archivos Lua, no para reglas.
--   • El bloque ips = {} mínimo evita que binders e inspectores
--     del sistema interfieran con las reglas alert tcp del lab.
-- =============================================================

output     = { logdir = '/var/log/snort' }
stream     = {}
stream_tcp = { session_timeout = 30 }

ips =
{
    -- 'rules' acepta texto de reglas Y directivas include.
    -- Esto carga lab_ransomware.rules directamente en el motor IPS.
    rules = [[ include /etc/snort/rules/lab_ransomware.rules ]],
}

alert_fast = { file = true }
