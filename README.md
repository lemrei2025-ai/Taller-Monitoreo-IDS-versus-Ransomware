# 🛡️ Lab IDS + Ransomware (Simulado) — Kali Linux

> Laboratorio educativo de ciberseguridad para practicar detección de malware e indicadores de compromiso con Snort, iptables y tcpdump en Kali Linux.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Kali Linux](https://img.shields.io/badge/Platform-Kali%20Linux-557C94?logo=kalilinux)](https://www.kali.org/)
[![Snort](https://img.shields.io/badge/IDS-Snort-red)](https://www.snort.org/)
[![Educational](https://img.shields.io/badge/Purpose-Educational-green)](docs/guia_estudiante.md)

---

## ⚠️ Aviso importante

Este repositorio contiene **únicamente herramientas educativas y simuladores inofensivos**:
- El "malware" es el [archivo de prueba EICAR](https://www.eicar.org/) (estándar de la industria, no es código malicioso).
- El "ransomware" es un simulador que **solo renombra archivos señuelo** y envía tráfico HTTP de práctica.
- No hay cifrado real, no hay persistencia, no hay propagación.

**Ejecutar siempre en una red aislada (VirtualBox Host-Only / Internal Network).**

---

## 🎯 ¿Qué aprenderán los estudiantes?

- Configurar y ejecutar Snort como IDS en Kali Linux
- Interpretar alertas de Snort ante indicadores de compromiso
- Reconocer patrones de tráfico de ransomware (beacons, C2)
- Escribir reglas Snort personalizadas
- Crear reglas de bloqueo con iptables
- Activar un **kill switch** para detener un ataque (como WannaCry)
- Capturar tráfico con tcpdump y analizar PCAPs

---

## 🗺️ Topología

```
┌─────────────────────────────────────────────────────────────┐
│                     Red Aislada (Host-Only)                  │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   VÍCTIMA    │◄──►│  ANALISTA    │◄──►│  ATACANTE    │  │
│  │  Kali Linux  │    │  Kali Linux  │    │  Kali Linux  │  │
│  │              │    │              │    │              │  │
│  │ Documentos   │    │ Snort IDS    │    │ Servidor C2  │  │
│  │ señuelo      │    │ iptables FW  │    │ + "malware"  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

> **Modo básico:** Una sola Kali Linux con múltiples terminales.

---

## 📁 Estructura del Repositorio

```
lab-ids-ransomware-kali/
├── README.md                        ← Este archivo
├── LICENSE
├── .gitignore
├── scripts/
│   ├── 00_preparar_entorno.sh       ← Setup inicial + archivos señuelo
│   ├── 01_servidor_malicioso.sh     ← Servidor HTTP con archivo EICAR
│   ├── 02_listener_c2.py            ← Panel C2 de práctica (solo logs)
│   ├── 03_simulador_ioc.py          ← Simulador de indicadores ransomware
│   ├── 04_iniciar_snort.sh          ← Arranca Snort con las reglas del lab
│   ├── 04b_monitorear_alertas.sh    ← Monitor de alertas en tiempo real
│   ├── 05_restaurar_sistema.sh      ← Revierte todos los cambios
│   └── 06_verificar_flags.sh        ← Sistema de puntuación CTF 🏆
├── snort_rules/
│   └── lab_ransomware.rules         ← 9 reglas Snort personalizadas
└── docs/
    ├── guia_estudiante.md           ← Guía con 14 preguntas + 5 retos
    └── guia_instructor.md           ← Respuestas, rúbrica, troubleshooting
```

---

## 🚀 Inicio rápido

### Requisitos
- Kali Linux (2023 o superior)
- 2 GB RAM mínimo
- Snort, Python 3, iptables, tcpdump (el script 00 los instala si faltan)

### Instalación

```bash
git clone https://github.com/<tu-usuario>/lab-ids-ransomware-kali.git
cd lab-ids-ransomware-kali
chmod +x scripts/*.sh
sudo bash scripts/00_preparar_entorno.sh
```

### Flujo del laboratorio

| Terminal | Rol | Comando |
|----------|-----|---------|
| A | Atacante: servidor malicioso | `bash scripts/01_servidor_malicioso.sh` |
| B | Analista: Snort IDS | `sudo bash scripts/04_iniciar_snort.sh` |
| C | Analista: monitor alertas | `bash scripts/04b_monitorear_alertas.sh` |
| D | Víctima: descarga + IOC | `wget ...` y `python3 scripts/03_simulador_ioc.py <IP>` |
| E (opt.) | Atacante: panel C2 | `python3 scripts/02_listener_c2.py` |

Consulta la [Guía del Estudiante](docs/guia_estudiante.md) para las instrucciones completas.

---

## 🏆 Sistema de Retos CTF

| Reto | Objetivo | Puntos |
|------|----------|--------|
| 1 | Detectar descarga del archivo EICAR con Snort | 20 pts |
| 2 | Detectar y analizar los beacons al C2 | 20 pts |
| 3 | Bloquear el C2 con iptables | 20 pts |
| 4 | Escribir una regla Snort propia | 20 pts |
| 5 | Restaurar el sistema y activar el kill switch | 20 pts |

**Verificar puntuación:**
```bash
bash scripts/06_verificar_flags.sh
```

---

## 🎓 Para Docentes

Ver la [Guía del Instructor](docs/guia_instructor.md) para:
- Respuestas a las 14 preguntas de reflexión
- Rúbrica de evaluación
- Opciones de despliegue (una VM vs. dos VMs)
- Solución de problemas comunes

---

## 🔧 Reglas Snort incluidas

El archivo `snort_rules/lab_ransomware.rules` incluye 9 reglas que detectan:

1. Firma del archivo EICAR en payload TCP
2. Nombre de archivo malicioso en URI HTTP
3. User-Agent del simulador IOC
4. Ruta `/beacon` en peticiones al C2
5. Consulta al kill switch (`/killswitch`)
6. Descarga de scripts PowerShell sospechosos
7. Conexiones salientes al puerto 4444 (C2)
8. Descargas desde servidor en puerto 8080
9. BONUS: Nombre de nota de rescate en tráfico de red

---

## 📜 Licencia

MIT — ver [LICENSE](LICENSE). Libre para uso educativo y adaptación.

---

*Desarrollado con fines educativos. Las técnicas mostradas son simulaciones controladas para entornos de laboratorio.*
