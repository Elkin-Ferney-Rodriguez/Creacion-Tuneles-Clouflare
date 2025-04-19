#!/bin/bash

RUTA_PROYECTO="$HOME/Contenedores/InstalacioCloudflared"
clear

while true; do
    echo "============================="
    echo "     GESTOR DE TÚNELES"
    echo "        CLOUDFLARED"
    echo "============================="
    echo "1) Crear nuevo túnel"
    echo "2) Ver túneles existentes"
    echo "3) Eliminar túnel"
    echo "0) Salir"
    echo "============================="
    read -p "Selecciona una opción: " opcion
    echo

    case "$opcion" in
        1)
            bash "$RUTA_PROYECTO/scripts/crear_tunel.sh"
            ;;
        2)
            bash "$RUTA_PROYECTO/scripts/ver_tuneles.sh"
            ;;
        3)
            bash "$RUTA_PROYECTO/scripts/eliminar_tunel.sh"
            ;;
        0)
            echo "👋 ¡Hasta luego!"
            exit 0
            ;;
        *)
            echo "❌ Opción inválida. Intenta nuevamente."
            ;;
    esac

    echo
    read -p "Presiona Enter para volver al menú..."
    clear
done
