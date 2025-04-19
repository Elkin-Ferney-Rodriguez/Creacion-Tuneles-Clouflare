#!/bin/bash

# Importar función de verificación de login si existe
if [[ -f "$(dirname "$0")/verificar_login.sh" ]]; then
    source "$(dirname "$0")/verificar_login.sh"
    # Verificar login
    verificar_login || exit 1
fi

clear
echo -e "\n=== TÚNELES ACTIVOS ===\n"
TUNNEL_LIST=$(cloudflared tunnel list 2>&1)
echo "$TUNNEL_LIST"
echo

# Comprobar si hay túneles o si hubo un error
if echo "$TUNNEL_LIST" | grep -q "No tunnels were found"; then
    echo "No hay túneles activos para mostrar."
    read -p "Presiona Enter para continuar..."
    exit 0
fi

if ! echo "$TUNNEL_LIST" | grep -q "NAME"; then
    echo "❌ Error al listar los túneles."
    read -p "Presiona Enter para continuar..."
    exit 1
fi

# Contar túneles (excluyendo la cabecera)
TUNELES_COUNT=$(echo "$TUNNEL_LIST" | wc -l)
if [[ $TUNELES_COUNT -gt 2 ]]; then
    read -p "¿Deseas ver más detalles de un túnel? (s/n): " VER
    if [[ "$VER" =~ ^[Ss]$ ]]; then
        echo "Túneles disponibles:"
        TUNNELS=$(echo "$TUNNEL_LIST" | tail -n +2 | awk '{print NR ") " $2}')
        echo "$TUNNELS"
        read -p "Selecciona el número del túnel: " TUNEL_NUM
        
        NOMBRE_TUNEL=$(echo "$TUNNEL_LIST" | tail -n +2 | awk '{print $2}' | sed -n "${TUNEL_NUM}p")
        
        if [[ -z "$NOMBRE_TUNEL" ]]; then
            echo "❌ Selección inválida."
            read -p "Presiona Enter para continuar..."
            exit 1
        fi
        
        echo -e "\n📄 Información detallada del túnel '$NOMBRE_TUNEL':"
        TUNNEL_INFO=$(cloudflared tunnel info "$NOMBRE_TUNEL" 2>&1)
        echo "$TUNNEL_INFO"
        
        if echo "$TUNNEL_INFO" | grep -q "error"; then
            echo "❌ No se pudo obtener la información del túnel."
            read -p "Presiona Enter para continuar..."
            exit 1
        fi
        
        echo -e "\n🛠️ Estado del servicio systemd:"
        systemctl status "cloudflared-$NOMBRE_TUNEL.service" --no-pager || echo "❌ El servicio no está instalado o activo."
    fi
fi

read -p "Presiona Enter para continuar..."
exit 0