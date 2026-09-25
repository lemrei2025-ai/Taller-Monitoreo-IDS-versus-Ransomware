# 🛡️ Laboratorio: IDS y Detección de Ransomware en Kali Linux

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
│                  Red Host-Only (aislada)                     │
│                                                             │
│  Terminal A          Terminal B/C         Terminal D        │
│  ┌───────────┐      ┌───────────┐        ┌───────────┐     │
│  │ ATACANTE  │      │ ANALISTA  │        │  VÍCTIMA  │     │
│  │           │      │           │        │           │     │
│  │ Servidor  │◄────►│ Snort IDS │◄──────►│ Documentos│     │
│  │ malicioso │      │ iptables  │        │ señuelo   │     │
│  │ Panel C2  │      │ tcpdump   │        │           │     │
│  └───────────┘      └───────────┘        └───────────┘     │
└─────────────────────────────────────────────────────────────┘

  ⚠  Todo ocurre en la misma Kali Linux usando 4 terminales.
```

> **Una sola Kali Linux** con 4 terminales abiertas es suficiente. Los roles "Atacante", "Analista" y "Víctima" se simulan en terminales separadas.

---

## ⚠️ Aviso de Seguridad

> Este laboratorio es **100% inofensivo**:
> - El "malware" es el **archivo EICAR** — estándar de la industria para probar IDS/AV, no es código malicioso.
> - El "ransomware" **no cifra nada**: solo renombra archivos señuelo y envía tráfico HTTP de práctica.
> - Ningún proceso persiste al reinicio. Nada toca archivos fuera del directorio del repositorio (`data/`).

---

## ⚙️ Preparación (15 min)

### Clonar el repositorio

> **Importante:** clona en `/tmp` para evitar conflictos de rutas con sesiones anteriores.

```bash
cd /tmp
git clone https://github.com/lemrei2025-ai/Taller-Monitoreo-IDS-versus-Ransomware
cd Taller-Monitoreo-IDS-versus-Ransomware
chmod +x scripts/*.sh scripts/*.py
```

Todos los archivos del lab (archivos señuelo, PCAP, servidor) se crean **dentro de este directorio**, no en `$HOME`. Puedes ejecutar los scripts con o sin `sudo` — siempre calcularán su propia ruta correctamente.

El setup está dividido en **dos pasos** porque uno necesita Internet y el otro no.

### Paso 0-A — Instalar paquetes (requiere Internet / modo NAT)

Asegúrate de que tu VM tiene el adaptador de red en **modo NAT** antes de ejecutar:

```bash
sudo bash scripts/00a_instalar_paquetes.sh
```

Este script verifica la conexión, instala Snort, tcpdump, Python 3, iptables y net-tools, y te avisa si falta algo.

> **¿Ya tienes estas herramientas instaladas?** Salta directamente al Paso 0-B.

### Paso 0-B — Preparar el laboratorio (funciona en Host-Only, sin Internet)

Una vez instalados los paquetes, puedes cambiar la VM a **red Host-Only** y ejecutar:

```bash
sudo bash scripts/00b_preparar_lab.sh
```

Este script crea la carpeta de trabajo, genera los 8 archivos señuelo y te muestra la IP de tu interfaz de red. Anota esa IP, la vas a necesitar.

**IP de mi máquina:** `______________________`

---

## 🔴 RETO 1 — Descarga de malware simulado y primera alerta `[20 pts]`

**Escenario:** Un empleado descargó un archivo sospechoso desde Internet. Tú eres el analista SOC. Tu misión: detectar la descarga con Snort antes de que cause daño.

### Terminal A — Inicia el servidor malicioso

```bash
bash scripts/01_servidor_malicioso.sh
```

Verás la IP y los archivos disponibles. El servidor sirve un archivo de prueba **EICAR** con nombre `Factura_Urgente_2026.pdf.exe`.

### Terminal B — Inicia Snort

```bash
sudo bash scripts/04_iniciar_snort.sh
```

Snort arrancará y comenzará a analizar el tráfico de red en tiempo real.

### Terminal C — Abre el monitor de alertas

```bash
bash scripts/04b_monitorear_alertas.sh
```

Esta terminal quedará esperando alertas. Las mostrará en colores según el tipo de amenaza.

### Terminal D — Descarga el archivo sospechoso (rol: Víctima)

```bash
wget http://<TU_IP>:8080/Factura_Urgente_2026.pdf.exe
```

### Observa la alerta en Terminal C

Deberías ver algo como:

```
[**] [1:9000001:1] [LAB] Descarga archivo EICAR - Test malware detectado [**]
[Priority: 1] {TCP} <TU_IP>:8080 -> <TU_IP>:XXXXX
```

---

**❓ Pregunta 1:** ¿Qué campos de la alerta identifican al servidor origen y al destino?

**❓ Pregunta 2:** El archivo se llama `.pdf.exe`. ¿Qué técnica de engaño representa? ¿Por qué funciona en Windows?

**❓ Pregunta 3:** Abre `snort_rules/lab_ransomware.rules` y busca la regla `sid:9000001`. ¿Qué cadena de texto busca en el tráfico? ¿Por qué esa cadena es suficiente para detectar el archivo?

```bash
cat snort_rules/lab_ransomware.rules
```

---

## 🟠 RETO 2 — Detectar el beacon de ransomware `[20 pts]`

**Escenario:** El equipo víctima ya está "infectado". Ahora el ransomware se comunica con el servidor de Comando y Control (C2) del atacante enviando beacons periódicos. Debes detectar ese tráfico.

### Terminal A — Inicia el panel C2 de práctica

```bash
python3 scripts/02_listener_c2.py
```

Verás los beacons llegar en tiempo real.

### Terminal D — Ejecuta el simulador de IOC

```bash
python3 scripts/03_simulador_ioc.py <TU_IP>
```

El simulador hará tres cosas en orden:
1. Comprobará si hay un kill switch activo.
2. Renombrará los archivos señuelo a `.locked`.
3. Enviará 5 beacons HTTP al panel C2.

### Verifica en Terminal C que Snort generó alertas

---

**❓ Pregunta 4:** ¿Cuántos beacons se enviaron? ¿Cuántas alertas distintas generó Snort?

**❓ Pregunta 5:** Ejecuta el siguiente comando y observa los archivos:

```bash
ls data/victima_documentos/
```

¿Qué cambió respecto al estado inicial? ¿Qué haría un ransomware real en lugar de renombrar?

**❓ Pregunta 6 — Kill switch:** Activa el kill switch y vuelve a correr el simulador:

```bash
# Debes estar dentro del directorio del repositorio
touch killswitch.flag
python3 scripts/03_simulador_ioc.py <TU_IP>
```

¿Qué ocurre ahora? ¿Por qué WannaCry tenía un mecanismo similar?

---

## 🔵 RETO 3 — Bloquear el C2 con iptables `[20 pts]`

**Escenario:** Identificaste la IP del C2. Ahora debes bloquearla en el firewall para que ningún equipo de la red pueda conectarse.

### Ver las reglas actuales del firewall

```bash
sudo iptables -L FORWARD -v -n
```

**❓ Pregunta 7:** ¿Cuál es la política actual de la cadena FORWARD? ¿Es seguro ese valor por defecto?

### Bloquear el servidor malicioso (puerto 8080)

```bash
sudo iptables -I FORWARD -p tcp --dport 8080 -j DROP
```

### Bloquear el C2 (puerto 4444)

```bash
sudo iptables -I FORWARD -p tcp --dport 4444 -j DROP
```

### Verificar las reglas

```bash
sudo iptables -L FORWARD -v -n
```

### Intentar la descarga nuevamente

```bash
wget http://<TU_IP>:8080/Factura_Urgente_2026.pdf.exe
```

---

**❓ Pregunta 8:** ¿La descarga se completó? ¿Por qué dice "timed out" en lugar de "Connection refused"?

**❓ Pregunta 9:** Escribe el comando para bloquear **toda la IP** del atacante en lugar de solo los puertos:

```bash
# Tu respuesta:
sudo iptables ________________________________________________
```

---

## 🟣 RETO 4 — Escribe tu propia regla Snort `[20 pts]`

**Escenario:** El atacante actualizó su herramienta y cambió el User-Agent a `MiRansomware/2.0`. La regla existente ya no lo detecta. Debes escribir una nueva.

### Tu tarea

Abre el archivo de reglas:

```bash
nano snort_rules/lab_ransomware.rules
```

Agrega al final una regla con **SID 9000010** que:
- Detecte el User-Agent `MiRansomware` en tráfico HTTP saliente.
- Use el mensaje: `"[LAB] RETO4 - Nuevo agente C2 detectado"`.

> **Pista:** Usa como modelo la regla `sid:9000003` que ya está en el archivo.

### Prueba tu regla

En `scripts/03_simulador_ioc.py`, cambia la línea:
```python
UA = "LabRansomSim/1.0"
```
por:
```python
UA = "MiRansomware/2.0"
```

Reinicia Snort y vuelve a ejecutar el simulador. Si tu regla es correcta, deberías ver la nueva alerta.

---

**❓ Pregunta 10:** Pega aquí la regla Snort que escribiste:

```
alert __________________________________________________________
```

**❓ Pregunta 11:** ¿Qué significa el campo `rev:` en una regla Snort? ¿Por qué se incrementa cada vez que se modifica?

---

## 🏅 RETO BONUS — Captura PCAP con tcpdump `[+10 pts]`

Captura el tráfico mientras el simulador envía beacons:

```bash
# Iniciar captura en segundo plano (dentro del directorio del repo)
sudo tcpdump -i any -w data/capturas/beacon.pcap &

# Ejecutar el simulador
python3 scripts/03_simulador_ioc.py <TU_IP>

# Detener la captura
fg
# Ctrl+C

# Leer la captura
tcpdump -r data/capturas/beacon.pcap -A | grep -i beacon
```

**❓ Pregunta 12:** ¿Qué información del beacon puedes ver en el PCAP? ¿Por qué esto es útil en una investigación forense?

---

## ✅ Verificar tu puntuación

```bash
bash scripts/06_verificar_flags.sh
```

| Puntuación | Insignia |
|-----------|---------|
| 100 pts   | 🥇 Cazador de Amenazas |
| 60–80 pts | 🥈 Analista SOC Jr. |
| 40–60 pts | 🥉 Aprendiz de Seguridad |
| < 40 pts  | 📚 Sigue practicando |

---

## 🔄 Restaurar el sistema

Al terminar o si quieres repetir el lab desde cero:

```bash
bash scripts/05_restaurar_sistema.sh
```

Esto revierte los archivos `.locked`, elimina la nota de rescate ficticia y limpia las reglas iptables del lab.

---

## 📚 Glosario

| Término | Definición |
|---------|-----------|
| **IDS** | Sistema de Detección de Intrusiones: monitorea el tráfico y genera alertas. |
| **Snort** | IDS/IPS de código abierto. Usa reglas con `sid` único para identificar amenazas. |
| **iptables** | Herramienta de firewall del kernel Linux para filtrar paquetes de red. |
| **EICAR** | Archivo de prueba estándar para verificar que un IDS/AV funciona, sin riesgo real. |
| **C2** | Servidor de Comando y Control: el atacante lo usa para dar órdenes al malware. |
| **Beacon** | Señal periódica que el malware envía al C2 para indicar que está activo. |
| **Kill switch** | Condición que detiene automáticamente un malware (como el de WannaCry en 2017). |
| **IOC** | Indicador de Compromiso: evidencia observable de un sistema atacado. |
| **PCAP** | Archivo de captura de paquetes de red para análisis forense. |

---

*Laboratorio educativo — todas las "amenazas" son simulaciones inofensivas en entorno controlado.*
