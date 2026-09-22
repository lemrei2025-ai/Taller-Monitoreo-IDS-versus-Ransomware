# 🛡️ Lab IDS + Ransomware (Simulado) — Kali Linux

> Laboratorio educativo de ciberseguridad para practicar detección de malware e indicadores de compromiso con Snort, iptables y tcpdump en Kali Linux.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Kali Linux](https://img.shields.io/badge/Platform-Kali%20Linux-557C94?logo=kalilinux)](https://www.kali.org/)
[![Snort](https://img.shields.io/badge/IDS-Snort-red)](https://www.snort.org/)
[![Educational](https://img.shields.io/badge/Purpose-Educational-green)](docs/guia_estudiante.md)

---

## ⚠️ Aviso importante

Este repositorio contiene **únicamente herramientas educativas y simuladores inofensivos**:
- El "malware" es el [archivo de prueba EICAR](https://www.eicar.org/) — no es código malicioso.
- El "ransomware" es un simulador que **solo renombra archivos señuelo** y envía tráfico HTTP de práctica.
- No hay cifrado real, no hay persistencia, no hay propagación.
- No supone ningún riesgo para el equipo anfitrión.

**Ejecutar siempre en una red aislada (VirtualBox Host-Only / Internal Network).**

---

## 🎯 ¿Qué aprenderán los estudiantes?

- Configurar y ejecutar Snort como IDS en Kali Linux
- Interpretar alertas de Snort ante indicadores de compromiso (IOC)
- Reconocer patrones de tráfico de ransomware (beacons, C2)
- Escribir reglas Snort personalizadas
- Crear reglas de bloqueo con iptables
- Activar un **kill switch** para detener un ataque (como WannaCry)
- Capturar tráfico con tcpdump y analizar PCAPs

---

## 🌐 Configuración de red (leer antes de empezar)

El lab usa **dos fases de red** distintas:

| Fase | Adaptador VirtualBox | Por qué |
|------|---------------------|---------|
| **Setup** — instalar paquetes | **NAT** | Necesita Internet para `apt install` |
| **Lab** — correr los retos | **Host-Only** | Aísla el tráfico simulado |

### Opción A — Dos adaptadores (recomendada)
1. Settings → Network en VirtualBox
   - Adaptador 1: **NAT** (Internet / apt)
   - Adaptador 2: **Host-Only** (red del lab)
2. Instala con `00a_instalar_paquetes.sh` (usa NAT).
3. El tráfico del lab circula por la interfaz Host-Only.

### Opción B — Un adaptador, dos pasos
1. Adaptador en **NAT** → ejecuta `00a_instalar_paquetes.sh`
2. Cambia a **Host-Only** → ejecuta `00b_preparar_lab.sh`
3. Corre los retos.

---

## 📁 Estructura del Repositorio

```
lab-ids-ransomware-kali/
├── README.md
├── LICENSE
├── .gitignore
├── scripts/
│   ├── 00a_instalar_paquetes.sh     ← [NAT]       Instala Snort, tcpdump, etc.
│   ├── 00b_preparar_lab.sh          ← [Host-Only]  Crea carpetas y archivos señuelo
│   ├── 01_servidor_malicioso.sh     ← Servidor HTTP con archivo EICAR
│   ├── 02_listener_c2.py            ← Panel C2 de práctica (solo registra beacons)
│   ├── 03_simulador_ioc.py          ← Simulador: renombra señuelos + beacons HTTP
│   ├── 04_iniciar_snort.sh          ← Arranca Snort con las reglas del lab
│   ├── 04b_monitorear_alertas.sh    ← Monitor de alertas en tiempo real con colores
│   ├── 05_restaurar_sistema.sh      ← Revierte todos los cambios del lab
│   └── 06_verificar_flags.sh        ← 🏆 Sistema CTF: verifica los 5 retos
├── snort_rules/
│   └── lab_ransomware.rules         ← 9 reglas Snort personalizadas
└── docs/
    └── guia_estudiante.md           ← Guía completa con 4 retos + 12 preguntas
```

---

## 🚀 Inicio rápido

### Requisitos
- Kali Linux 2023 o superior
- 2 GB RAM mínimo
- VirtualBox o VMware

### Instalación

```bash
git clone https://github.com/<tu-usuario>/lab-ids-ransomware-kali.git
cd lab-ids-ransomware-kali
chmod +x scripts/*.sh scripts/*.py
```

### Setup (con adaptador NAT activo)

```bash
sudo bash scripts/00a_instalar_paquetes.sh
```

### Preparar el lab (cambia a Host-Only primero)

```bash
sudo bash scripts/00b_preparar_lab.sh
```

### Flujo del laboratorio — 4 terminales

| Terminal | Comando |
|----------|---------|
| A — Atacante | `bash scripts/01_servidor_malicioso.sh` |
| B — IDS | `sudo bash scripts/04_iniciar_snort.sh` |
| C — Monitor | `bash scripts/04b_monitorear_alertas.sh` |
| D — Víctima | `wget ...` → `python3 scripts/03_simulador_ioc.py <IP>` |

Ver [`docs/guia_estudiante.md`](docs/guia_estudiante.md) para las instrucciones completas.

---

## 🏆 Sistema de Retos CTF

| Reto | Objetivo | Pts |
|------|----------|-----|
| 1 | Detectar la descarga del archivo EICAR con Snort | 20 |
| 2 | Detectar y analizar los beacons al C2 + kill switch | 20 |
| 3 | Bloquear el C2 con iptables | 20 |
| 4 | Escribir una regla Snort propia | 20 |
| 5 | Restaurar el sistema | 20 |
| Bonus | Captura PCAP con tcpdump | +10 |

```bash
bash scripts/06_verificar_flags.sh
```

---

## 🔧 Reglas Snort incluidas

El archivo `snort_rules/lab_ransomware.rules` incluye 9 reglas que detectan:
firma EICAR en payload, nombre de archivo malicioso en URI, User-Agent del simulador IOC,
ruta `/beacon` al C2, consulta al kill switch, scripts PowerShell, conexiones al puerto 4444,
descargas desde puerto 8080 y nombre de nota de rescate en tráfico de red.

---

## 📜 Licencia

MIT — ver [LICENSE](LICENSE). Libre para uso educativo y adaptación.

---

*Desarrollado con fines educativos. Las técnicas mostradas son simulaciones controladas.*
