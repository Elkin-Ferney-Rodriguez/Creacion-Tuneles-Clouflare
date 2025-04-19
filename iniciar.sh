#!/bin/bash

cd "$(dirname "$0")"

clear
echo "╔════════════════════════════════════════╗"
echo "║     GESTOR DE TÚNELES CLOUDFLARED      ║"
echo "╚════════════════════════════════════════╝"

PS3=$'\nSelecciona una opción: '
options=("Crear nuevo túnel" "Ver túneles activos" "Salir")

select opt in "${options[@]}"; do
  case $REPLY in
    1) bash scripts/crear_tunel.sh; break ;;
    2) cloudflared tunnel list; break ;;
    3) echo "Saliendo..."; exit 0 ;;
    *) echo "Opción inválida";;
  esac
done
