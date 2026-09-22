# 📋 Guía del Instructor — Laboratorio IDS y Detección de Ransomware

**Duración:** 90–120 minutos | **Nivel:** Intermedio | **Grupo recomendado:** 15–30 estudiantes

---

## 🔒 Notas de Seguridad (Leer ANTES de desplegar)

- Todo el "malware" de este laboratorio es **100% inofensivo**: archivo EICAR + simulador de IOC que solo renombra archivos señuelo.
- El simulador **no cifra contenido**, no persiste al reinicio y no se propaga.
- Debe ejecutarse en una **red aislada** (VirtualBox Host-Only o Internal Network).
- Verificar que los equipos de los estudiantes tengan Kali Linux con al menos 2 GB de RAM.

---

## 🚀 Despliegue

### Opción A — Una sola Kali Linux por estudiante (más sencillo)

Cada estudiante usa **4–5 terminales** en su propia Kali. Las IP del "atacante" y la "víctima" son la misma máquina (loopback o la IP de la interfaz de red). Es el modo más práctico para clases con recursos limitados.

### Opción B — Dos VMs por estudiante (más realista)

| VM | Sistema | IP sugerida | Rol |
|----|---------|------------|-----|
| VM1 | Kali Linux | 192.168.56.10 | Víctima + Analista (Snort) |
| VM2 | Kali Linux | 192.168.56.20 | Atacante (servidor + C2) |

Configurar ambas VMs en modo **Host-Only Adapter** en VirtualBox.

---

## ✅ Respuestas a las Preguntas

### Pregunta 1
> "¿Por qué es importante verificar las herramientas antes de comenzar?"

**Respuesta esperada:** Para no interrumpir el flujo del laboratorio a mitad. En un entorno de producción, un IDS sin las firmas actualizadas puede dejar pasar ataques. La verificación previa también es parte del proceso de hardening de un sistema.

---

### Pregunta 2
> "¿Qué campos de la alerta Snort identifican al atacante y a la víctima?"

**Respuesta esperada:**
- La parte `{TCP} 192.168.56.20:8080 -> 192.168.56.10:xxxxx` muestra:
  - `192.168.56.20:8080` = IP:puerto **origen** (servidor del atacante)
  - `192.168.56.10:xxxxx` = IP:puerto **destino** (víctima)

---

### Pregunta 3
> "¿Por qué el archivo se llama `.pdf.exe`?"

**Respuesta esperada:** Técnica de **extensión doble** (*double extension*) para engañar a usuarios que tienen ocultas las extensiones de archivo en Windows. El usuario ve "Factura_Urgente_2026.pdf" y cree que es un PDF legítimo, cuando en realidad es un ejecutable (.exe). Es una técnica de ingeniería social muy común en campañas de phishing con ransomware.

---

### Pregunta 4
> "¿Qué patrón busca la regla sid:9000001?"

**Respuesta esperada:** Busca la cadena `X5O!P%@AP[4` en el payload del paquete TCP. Esa es la firma inicial del archivo EICAR. Cualquier archivo que contenga esa cadena activará la alerta, independientemente del nombre del archivo.

---

### Pregunta 5
> "¿Cuántos beacons envió el simulador? ¿Cuántas alertas generó Snort?"

**Respuesta esperada:** Por defecto el simulador envía **5 beacons**. Snort debería generar al menos 5 alertas (una por beacon) para la regla sid:9000004 (`/beacon`), más alertas para el kill switch (sid:9000005).

---

### Pregunta 6
> "¿Qué información envía el beacon al C2?"

**Respuesta esperada:** El beacon incluye el hostname de la víctima (`id=`), el número de secuencia (`seq=`) y la cantidad de archivos "bloqueados" (`files=`). Un ransomware real enviaría además: la clave de cifrado, la lista de archivos cifrados, la versión del malware y datos del sistema (OS, idioma, dominio de AD).

---

### Pregunta 7
> "¿Qué diferencia hay con el estado inicial?"

**Respuesta esperada:** Los archivos pasaron de `.txt` a `.txt.locked`. Un ransomware real usaría un algoritmo de cifrado asimétrico (RSA) o simétrico (AES-256) para cifrar el **contenido** de los archivos, haciendo que sean irrecuperables sin la clave privada del atacante.

---

### Pregunta 8
> "¿Qué ocurre al activar el kill switch?"

**Respuesta esperada:** El simulador se detiene inmediatamente sin renombrar archivos. El kill switch fue el mecanismo que detuvo a WannaCry en 2017: el investigador Marcus Hutchins registró el dominio que el malware consultaba (iuqerfsodp9ifjaposdfjhgosurijfaewrwergwea.com). Al recibir respuesta HTTP 200, WannaCry interpretaba que estaba siendo analizado en sandbox y se detenía. Hutchins lo registró y detuvo el brote global.

---

### Pregunta 9
> "¿Qué significa política ACCEPT en FORWARD?"

**Respuesta esperada:** Que todo el tráfico que atraviesa el firewall se permite por defecto si no hay ninguna regla que lo bloquee. Esto es el enfoque **permisivo** ("permit by default"). El enfoque más seguro es **"deny by default"** (política DROP) y permitir explícitamente solo el tráfico autorizado.

---

### Pregunta 10
> "¿Por qué dice 'timed out' en lugar de 'refused'?"

**Respuesta esperada:** `Connection refused` ocurriría si el servidor respondiera con un RST/ACK. `Connection timed out` indica que los paquetes están siendo **descartados silenciosamente** (DROP en iptables). La acción REJECT respondería con un paquete de error, lo que confirma al atacante que hay un firewall. DROP no revela esa información.

---

### Pregunta 11
> "Comando para bloquear toda la IP del atacante"

**Respuesta esperada:**
```bash
sudo iptables -I FORWARD -p tcp -d <IP_ATACANTE> -j DROP
```
o más amplio:
```bash
sudo iptables -I FORWARD -s <IP_ATACANTE> -j DROP
sudo iptables -I FORWARD -d <IP_ATACANTE> -j DROP
```

**Discusión:** Bloquear toda la IP es más agresivo pero puede causar falsos positivos si el atacante está usando una IP compartida (CDN, NAT). Bloquear solo los puertos maliciosos es más quirúrgico pero el atacante puede cambiar de puerto.

---

### Pregunta 12
> "Regla Snort para MiRansomware/2.0"

**Respuesta esperada:**
```
alert tcp $HOME_NET any -> $EXTERNAL_NET any \
  (msg:"[LAB] RETO4 - Nuevo agente C2 detectado"; \
   content:"MiRansomware"; http_header; nocase; \
   classtype:command-and-control; sid:9000010; rev:1;)
```

---

### Pregunta 13
> "¿Qué significa el campo `rev:` en Snort?"

**Respuesta esperada:** Es el número de **revisión** de la regla. Cada vez que se modifica una regla, se incrementa rev. Junto con el SID, el par `sid:rev:` identifica de forma única una versión específica de una regla. Esto es clave para la gestión de reglas en producción, actualizaciones de firmas y trazabilidad de incidentes.

---

### Pregunta 14
> "¿Qué ventaja aporta el PCAP?"

**Respuesta esperada:** Un PCAP permite reconstruir exactamente qué datos viajaron por la red, incluyendo el contenido del payload. Los analistas pueden: analizar el tráfico offline con Wireshark, extraer archivos transferidos, reconstruir la sesión HTTP, identificar C2 y TTPs (tácticas, técnicas y procedimientos) del atacante, y usarlo como evidencia forense.

---

## 📊 Rúbrica de Evaluación

| Criterio | Excelente (5) | Bueno (3) | Necesita mejora (1) |
|----------|--------------|-----------|-------------------|
| Snort operativo y generando alertas | Sin ayuda, primera vez | Con un intento | Requirió asistencia directa |
| Interpretación de alertas | Identifica todos los campos y su significado | Identifica IP/puertos | Solo describe qué vio |
| Regla iptables correcta | Sintaxis perfecta y razonamiento explicado | Sintaxis correcta sin explicación | Con errores de sintaxis |
| Regla Snort propia (Reto 4) | Funciona y explica cada campo | Funciona pero sin explicación | No funciona |
| Respuestas de reflexión | Completas, con conceptos propios | Completas pero superficiales | Incompletas |

**Puntuación máxima del script CTF:** 100 puntos (5 retos × 20 pts)

---

## 🔧 Solución de Problemas Comunes

**"Snort no arranca / error en snort.conf"**  
→ Verificar que `/etc/snort/snort.conf` existe. Si no: `sudo apt install snort` y aceptar la configuración interactiva. La variable `HOME_NET` debe estar configurada.

**"La regla Snort no genera alertas"**  
→ Verificar que la interfaz de red en `04_iniciar_snort.sh` es la correcta con `ip -brief addr show`. Asegurarse de que el tráfico pasa por esa interfaz.

**"wget dice 'Connection timed out' desde el inicio"**  
→ El estudiante puede haber ejecutado el Reto 3 antes del 1. Limpiar con `05_restaurar_sistema.sh`.

**"El simulador dice 'No existe victima_documentos'"**  
→ No ejecutaron `00_preparar_entorno.sh`. Pedirles que lo ejecuten primero.

---

## 📖 Referencias Adicionales para el Docente

- [Snort Rule Writing Guide](https://snort-org-site.s3.amazonaws.com/production/document_files/files/000/000/116/original/Snort_rule_infographic.pdf)
- [EICAR Standard Test File](https://www.eicar.org/download-anti-malware-testfile/)
- [Historia del kill switch de WannaCry — MalwareTech](https://www.malwaretech.com/2017/05/how-to-accidentally-stop-a-global-cyber-attacks.html)
- [iptables Tutorial](https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html)

---

*Guía del instructor — uso exclusivo del educador. No distribuir a estudiantes antes del laboratorio.*
