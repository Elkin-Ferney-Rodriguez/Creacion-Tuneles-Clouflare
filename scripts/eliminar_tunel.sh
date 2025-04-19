#!/bin/bash

CONFIG_BASE="$HOME/Contenedores/InstalacioCloudflared"
CONFIG_DIR="$CONFIG_BASE/configs/tunnels"
SERVICE_DIR="/etc/systemd/system"
CRED_DIR="$CONFIG_BASE/credenciales"

# Verificación de login si corresponde
if [[ -f "$(dirname "$0")/verificar_login.sh" ]]; then
    source "$(dirname "$0")/verificar_login.sh"
    verificar_login || exit 1
fi

clear
echo "===== ELIMINAR TÚNEL CLOUDFLARED ====="

# Obtener lista de túneles
TUNNEL_LIST=$(cloudflared tunnel list 2>&1)
if echo "$TUNNEL_LIST" | grep -q "No tunnels were found"; then
    echo "❌ No hay túneles disponibles para eliminar."
    read -p "Presiona Enter para continuar..."
    exit 0
fi

# Mostrar túneles numerados
echo "$TUNNEL_LIST" | tail -n +2 | awk '{print NR ") " $2 " (ID: " $1 ")"}'
echo "0) Salir"
echo "======================================"
read -p "Selecciona el número del túnel a eliminar: " seleccion

# Validación
TUNNEL_COUNT=$(echo "$TUNNEL_LIST" | tail -n +2 | wc -l)
if [[ "$seleccion" == "0" ]]; then
    echo "Saliendo..."
    exit 0
elif ! [[ "$seleccion" =~ ^[0-9]+$ ]] || (( seleccion < 1 || seleccion > TUNNEL_COUNT )); then
    echo "❌ Selección inválida."
    read -p "Presiona Enter para continuar..."
    exit 1
fi

ID_TUNEL=$(echo "$TUNNEL_LIST" | tail -n +2 | awk '{print $1}' | sed -n "${seleccion}p")
NOMBRE_TUNEL=$(echo "$TUNNEL_LIST" | tail -n +2 | awk '{print $2}' | sed -n "${seleccion}p")

if [[ -z "$ID_TUNEL" || -z "$NOMBRE_TUNEL" ]]; then
    echo "❌ No se pudo obtener la información del túnel."
    read -p "Presiona Enter para continuar..."
    exit 1
fi

# Mostrar estado del servicio
if systemctl is-active --quiet "cloudflared-$NOMBRE_TUNEL.service"; then
    echo "⚠️ El túnel '$NOMBRE_TUNEL' está activo. Deteniéndolo..."
    sudo systemctl stop "cloudflared-$NOMBRE_TUNEL.service"
fi

# Obtener hostname del túnel
TUNNEL_INFO=$(cloudflared tunnel info "$ID_TUNEL" 2>&1)
HOSTNAME=$(echo "$TUNNEL_INFO" | grep -oP "(?<=CNAME: ).*?(?=$)" | head -1)
[[ -z "$HOSTNAME" ]] && HOSTNAME=$(echo "$TUNNEL_INFO" | grep -oP "(?<=hostname: ).*?(?=$)" | head -1)

# Cleanup conexiones
echo "🔍 Ejecutando cleanup de conexiones..."
cloudflared tunnel cleanup "$ID_TUNEL" &>/dev/null

# Eliminar DNS
if [[ -n "$HOSTNAME" ]]; then
    echo "🗑️ Eliminando registro DNS para $HOSTNAME..."
    cloudflared tunnel route dns -d "$HOSTNAME" "$ID_TUNEL" &>/dev/null || \
    echo "⚠️ No se pudo eliminar el registro DNS (puede ya no existir)."
fi

# Eliminar túnel
echo "🗑️ Eliminando túnel '$NOMBRE_TUNEL'..."
DELETE_OUTPUT=$(cloudflared tunnel delete "$ID_TUNEL" 2>&1)
if echo "$DELETE_OUTPUT" | grep -qi "error"; then
    echo "⚠️ Error al eliminar el túnel: $DELETE_OUTPUT"
    read -p "¿Deseas continuar con la limpieza de archivos locales? (s/N): " CONTINUE
    [[ ! "$CONTINUE" =~ ^[Ss]$ ]] && exit 1
fi

# Eliminar servicio systemd
if [[ -f "$SERVICE_DIR/cloudflared-$NOMBRE_TUNEL.service" ]]; then
    echo "🧹 Eliminando servicio systemd..."
    sudo systemctl disable "cloudflared-$NOMBRE_TUNEL.service" &>/dev/null || true
    sudo rm -f "$SERVICE_DIR/cloudflared-$NOMBRE_TUNEL.service"
    sudo systemctl daemon-reload
fi

# Eliminar archivos de configuración y credenciales
CONFIG_PATH="$CONFIG_DIR/$NOMBRE_TUNEL"
CRED_FILE="$CRED_DIR/$NOMBRE_TUNEL.json"

[[ -d "$CONFIG_PATH" ]] && rm -rf "$CONFIG_PATH" && echo "✅ Configuración eliminada."
[[ -f "$CRED_FILE" ]] && rm -f "$CRED_FILE" && echo "✅ Credenciales eliminadas."

echo "✅ Túnel '$NOMBRE_TUNEL' eliminado correctamente."

read -p "¿Deseas eliminar otro túnel? (s/N): " repetir
[[ "$repetir" =~ ^[Ss]$ ]] && exec "$0"

exit 0
