#!/bin/bash

# Parámetros: $1=nombre_tunel, $2=id_tunel, $3=ruta_config
NOMBRE_TUNEL="$1"
ID_TUNEL="$2"
CONFIG_PATH="$3"

if [[ -z "$NOMBRE_TUNEL" || -z "$ID_TUNEL" || -z "$CONFIG_PATH" ]]; then
    echo "❌ Error: Faltan parámetros para crear el servicio."
    exit 1
fi

# Determinar el usuario real (incluso si se ejecuta con sudo)
USER_REAL="${SUDO_USER:-$(whoami)}"

# Verificar que cloudflared esté donde se espera
CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
if [[ ! -x "$CLOUDFLARED_BIN" ]]; then
    echo "❌ Error: cloudflared no está en $CLOUDFLARED_BIN o no es ejecutable."
    exit 1
fi

# Crear archivo de servicio systemd
cat > "/etc/systemd/system/cloudflared-$NOMBRE_TUNEL.service" <<EOF
[Unit]
Description=Cloudflare Tunnel for $NOMBRE_TUNEL
After=network.target

[Service]
Type=simple
User=$USER_REAL
ExecStart=$CLOUDFLARED_BIN tunnel --config $CONFIG_PATH run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "🛠️ Habilitando e iniciando el servicio cloudflared-$NOMBRE_TUNEL..."
systemctl daemon-reload
systemctl enable "cloudflared-$NOMBRE_TUNEL.service"
systemctl start "cloudflared-$NOMBRE_TUNEL.service"

echo "📡 Verificando estado del servicio..."
if systemctl is-active --quiet "cloudflared-$NOMBRE_TUNEL.service"; then
    echo "✅ El servicio cloudflared-$NOMBRE_TUNEL está activo y funcionando correctamente."
    exit 0
else
    echo "❌ Error: El servicio no se inició correctamente."
    systemctl status "cloudflared-$NOMBRE_TUNEL.service" --no-pager
    exit 1
fi
