#!/bin/bash

CONFIG_BASE="$HOME/Contenedores/InstalacioCloudflared"
CONFIG_DIR="$CONFIG_BASE/configs/tunnels"
SERVICE_DIR="/etc/systemd/system"
CRED_DIR="$CONFIG_BASE/credenciales"

# Importar función de verificación de login si existe
if [[ -f "$(dirname "$0")/verificar_login.sh" ]]; then
    source "$(dirname "$0")/verificar_login.sh"
    verificar_login || exit 1
fi

clear
echo "=== CREAR NUEVO TÚNEL CLOUDFLARED ==="
read -p "Nombre del túnel: " NOMBRE_TUNEL
NOMBRE_TUNEL=$(echo "$NOMBRE_TUNEL" | tr '[:upper:]' '[:lower:]' | xargs)

# Verificar si ya existe
if cloudflared tunnel list 2>/dev/null | grep -q "$NOMBRE_TUNEL"; then
    echo "⚠️ Ya existe un túnel con el nombre '$NOMBRE_TUNEL'."
    read -p "¿Deseas intentar con otro nombre? (s/n): " RETRY
    [[ "$RETRY" =~ ^[Ss]$ ]] && exec "$0" || exit 1
fi

read -p "Hostname (ej: servicio.devpersonal.site): " HOSTNAME
HOSTNAME=$(echo "$HOSTNAME" | tr '[:upper:]' '[:lower:]' | xargs)

read -p "Dirección local del servicio (ej: http://10.141.99.219:8000): " SERVICE_URL

# Verificar conexión al servicio
echo "🧪 Verificando si el servicio está accesible..."
if ! curl -sk --connect-timeout 3 "$SERVICE_URL" >/dev/null; then
    echo "⚠️ El servicio $SERVICE_URL no responde. Puede que esté apagado o mal configurado."
    read -p "¿Deseas continuar de todas formas? (s/n): " CONT
    [[ "$CONT" =~ ^[Ss]$ ]] || exit 1
fi

# Crear el túnel
echo "⏳ Registrando el túnel en Cloudflare..."
TUNNEL_OUTPUT=$(cloudflared tunnel create "$NOMBRE_TUNEL" 2>&1)
ID_TUNEL=$(echo "$TUNNEL_OUTPUT" | grep -oP "(?<=with id )[a-f0-9-]+")

if [[ -z "$ID_TUNEL" ]]; then
    echo "❌ Error al crear el túnel:"
    echo "$TUNNEL_OUTPUT"
    exit 1
fi

echo "🆔 ID del túnel creado: $ID_TUNEL"

# Crear directorios
mkdir -p "$CONFIG_DIR/$NOMBRE_TUNEL" "$CRED_DIR"

# Buscar archivo de credenciales
CRED_FILE="$HOME/.cloudflared/$ID_TUNEL.json"
[[ ! -f "$CRED_FILE" ]] && CRED_FILE=$(find "$HOME/.cloudflared" -name "*.json" -type f -mtime -1 | head -1)

if [[ -f "$CRED_FILE" ]]; then
    cp "$CRED_FILE" "$CRED_DIR/$ID_TUNEL.json"
    echo "✅ Credenciales copiadas."
else
    echo "⚠️ No se encontraron las credenciales. El túnel podría no funcionar."
fi

# Descomponer SERVICE_URL en IP y puerto
URL_CLEAN="${SERVICE_URL#*://}" # Quita http:// o https://
IP=$(echo "$URL_CLEAN" | cut -d':' -f1)
PUERTO=$(echo "$URL_CLEAN" | cut -d':' -f2)
PROTOCOLO=$(echo "$SERVICE_URL" | grep -oE '^https?')

# Ruta del archivo de configuración generado
DEST_CONFIG="$CONFIG_DIR/$NOMBRE_TUNEL/config.yml"

# Preguntar si se desea ignorar la verificación TLS
echo "¿Tu servicio usa HTTPS con certificado autofirmado o estás usando IP directa? (s/n)"
read -r usar_no_tls_verify

# Crear config.yml dinámicamente
cat > "$DEST_CONFIG" <<EOF
tunnel: $ID_TUNEL
credentials-file: $CRED_DIR/$ID_TUNEL.json

ingress:
  - hostname: $HOSTNAME
    service: $PROTOCOLO://$IP:$PUERTO
EOF

# Agregar originRequest si es necesario
if [[ "$usar_no_tls_verify" == "s" ]]; then
  cat >> "$DEST_CONFIG" <<EOF
    originRequest:
      noTLSVerify: true
EOF
fi

# Agregar catch-all
echo "  - service: http_status:404" >> "$DEST_CONFIG"

echo "📄 Configuración generada dinámicamente en: $DEST_CONFIG"

# Asociar DNS
echo "🌐 Verificando existencia previa del registro DNS..."
if cloudflared tunnel list | grep -i "$HOSTNAME" >/dev/null; then
    echo "⚠️ Ya existe un registro para $HOSTNAME. Eliminando..."
    cloudflared tunnel route dns -d "$HOSTNAME" "$ID_TUNEL" 2>/dev/null
fi

echo "🔄 Asociando DNS $HOSTNAME con el túnel..."
DNS_OUTPUT=$(cloudflared tunnel route dns "$ID_TUNEL" "$HOSTNAME" 2>&1)
echo "$DNS_OUTPUT"
echo "✅ Registro DNS creado."

# Crear script de inicio
cat > "$CONFIG_DIR/$NOMBRE_TUNEL/start.sh" <<EOF
#!/bin/bash
cloudflared tunnel run --config "$DEST_CONFIG" "$ID_TUNEL"
EOF
chmod +x "$CONFIG_DIR/$NOMBRE_TUNEL/start.sh"

# Crear y activar servicio systemd
echo "🛠️ Creando servicio systemd..."
sudo bash "$(dirname "$0")/crear_servicio.sh" "$NOMBRE_TUNEL" "$ID_TUNEL" "$DEST_CONFIG"
SERVICE_RESULT=$?

if [[ $SERVICE_RESULT -eq 0 ]]; then
    echo "✅ El servicio cloudflared-$NOMBRE_TUNEL está activo y funcionando correctamente."
    echo "🌐 Tu servicio está disponible en:  https://$HOSTNAME"
else
    echo "⚠️ El servicio no se inició correctamente. Verifica los logs."
fi

read -p "¿Deseas crear otro túnel? (s/n): " OTRO
[[ "$OTRO" =~ ^[Ss]$ ]] && exec "$0"

exit 0
