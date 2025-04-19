#!/bin/bash

verificar_login() {
    echo "🔑 Verificando autenticación de Cloudflared..."
    
    # Verificar si el token de Cloudflare existe
    if [[ ! -f "$HOME/.cloudflared/cert.pem" ]]; then
        echo "❌ No estás autenticado en Cloudflare."
        read -p "¿Deseas iniciar sesión ahora? (s/N): " LOGIN
        
        if [[ "$LOGIN" =~ ^[Ss]$ ]]; then
            echo "📝 Iniciando proceso de autenticación..."
            cloudflared login
            
            if [[ ! -f "$HOME/.cloudflared/cert.pem" ]]; then
                echo "❌ La autenticación falló. Por favor, intenta de nuevo más tarde."
                return 1
            else
                echo "✅ Autenticación exitosa."
                return 0
            fi
        else
            echo "⚠️ Se requiere autenticación para continuar."
            return 1
        fi
    else
        echo "✅ Ya estás autenticado en Cloudflare."
        return 0
    fi
}

# Si el script se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    verificar_login
    exit $?
fi