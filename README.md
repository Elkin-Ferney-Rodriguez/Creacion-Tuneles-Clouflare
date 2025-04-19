
```markdown
# Creación de Túneles Cloudflared

Este proyecto automatiza la creación, gestión y eliminación de túneles seguros usando **Cloudflared** en sistemas Linux. Ofrece un menú interactivo en Bash que guía paso a paso la configuración de túneles, ideal para acceder a servicios locales como Portainer, Nextcloud, etc. desde Internet de forma segura y sin exponer puertos directamente.

## 🚀 Características

- 🔐 Automatiza la autenticación con Cloudflare.
- ⚙️ Crea túneles personalizados con sus propios servicios systemd.
- 📜 Scripts organizados y personalizables.
- 🧹 Elimina túneles limpiando completamente archivos y servicios.
- 📋 Verifica túneles existentes y su estado actual.
- 🖥️ Interfaz por menú simple e intuitiva (bash).

## 📁 Estructura del proyecto

```
InstalacioCloudflared/
├── iniciar.sh
├── configs/
│   └── templates/
│       └── config_template.yml
├── credenciales/
├── logs/
├── scripts/
│   ├── crear_tunel.sh
│   ├── crear_servicio.sh
│   ├── eliminar_tunel.sh
│   ├── menu.sh
│   ├── verificar_login.sh
│   └── ver_tuneles.sh
```

## 🧰 Requisitos

- Linux (probado en Ubuntu)
- `cloudflared` instalado
- Cuenta en [Cloudflare](https://dash.cloudflare.com/)
- Zona o dominio registrado en Cloudflare

## ⚙️ Instalación

```bash
git clone https://github.com/Elkin-Ferney-Rodriguez/Creacion-Tuneles-Clouflare.git
cd Creacion-Tuneles-Clouflare
chmod +x iniciar.sh
./iniciar.sh
```

## 🧪 Ejemplo de uso

Desde el menú principal podrás:

- Crear un nuevo túnel
- Ver túneles existentes y su estado
- Eliminar túneles completamente
- Salir del programa

## ✍️ Autor

Proyecto creado por **[Elkin Ferney Rodríguez](https://github.com/Elkin-Ferney-Rodriguez)** como herramienta de automatización para DevOps personales.

---

¡Listo para usar y compartir con la comunidad!

```
