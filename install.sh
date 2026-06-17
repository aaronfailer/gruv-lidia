#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════
# Quickshell Dotfiles Installer
# ═══════════════════════════════════════════════════════════════

# ── Language strings ──────────────────────────────────────────

declare -A MSG_EN
declare -A MSG_ES

msg() {
  local key="$1"
  if [ "$LANG_SEL" = "es" ]; then
    echo "${MSG_ES[$key]}"
  else
    echo "${MSG_EN[$key]}"
  fi
}

prompt() {
  local key="$1"
  if [ "$LANG_SEL" = "es" ]; then
    echo -n "${MSG_ES[$key]}"
  else
    echo -n "${MSG_EN[$key]}"
  fi
}

# ── Language selection ────────────────────────────────────────

echo "╔══════════════════════════════════════════════════════════╗"
echo "║       Quickshell Dotfiles Installer                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Select language / Seleccione idioma:"
echo "  1) English"
echo "  2) Español"
echo -n "> "
read -r lang_choice

case "$lang_choice" in
  2|es|ES|español|espanol) LANG_SEL="es" ;;
  *) LANG_SEL="en" ;;
esac

# ── Fill translations ────────────────────────────────────────

MSG_EN=(
  ["title"]="==> Quickshell Dotfiles Installer"
  ["detect"]="==> Detecting system..."
  ["distro"]="  Distribution:"
  ["pkgmgr"]="  Package manager:"
  ["wayland"]="  Wayland session:"
  ["pkg_list"]="==> Packages to install (required)"
  ["pkg_opt"]="  Optional (skipped if not found)"
  ["pkg_confirm"]="  Proceed with package installation? [Y/n]"
  ["pkg_installing"]="==> Installing packages..."
  ["pkg_skip"]="  Skipping package installation."
  ["cfg_wallpaper"]="==> Wallpaper directory"
  ["cfg_wallpaper_desc"]="  Directory where theme wallpapers will be stored."
  ["cfg_wallpaper_default"]="  Default:"
  ["cfg_enter"]="  Enter path (or press Enter for default):"
  ["cfg_xdg"]="==> XDG user directories language"
  ["cfg_xdg_desc"]="  MenuPanel.qml uses shortcuts to Documents, Pictures, Music, Downloads."
  ["cfg_xdg_opt_es"]="  1) Spanish  (Documentos, Imágenes, Música, Descargas)"
  ["cfg_xdg_opt_en"]="  2) English  (Documents, Pictures, Music, Downloads)"
  ["cfg_xdg_opt_auto"]="  3) Auto-detect from locale"
  ["cfg_xdg_ask"]="  Choose [1-3]:"
  ["cfg_xdg_es"]="  → Using Spanish names"
  ["cfg_xdg_en"]="  → Using English names"
  ["cfg_xdg_auto"]="  → Auto-detected:"
  ["cfg_hypr"]="==> Hyprland config directory"
  ["cfg_hypr_desc"]="  Where hyprland.conf, hyprpaper.conf and scripts go."
  ["cfg_kitty"]="==> Kitty config directory"
  ["cfg_kitty_desc"]="  Where kitty.conf and theme files go."
  ["cfg_swaync"]="==> Swaync config directory"
  ["cfg_swaync_desc"]="  Where notification center config goes."
  ["cfg_fuzzel"]="==> Fuzzel config directory"
  ["cfg_fuzzel_desc"]="  Where app launcher config goes."
  ["cfg_starship"]="==> Starship config file"
  ["cfg_starship_desc"]="  Where the prompt config file goes."
  ["cfg_bashrc"]="==> Shell config"
  ["cfg_bashrc_desc"]="  Append aliases, starship and fzf setup to ~/.bashrc?"
  ["cfg_bashrc_ask"]="  Proceed? [Y/n]"
  ["deploy"]="==> Deploying configuration files..."
  ["deploy_wall"]="  Copying wallpapers..."
  ["deploy_hypr"]="  Deploying Hyprland config..."
  ["deploy_kitty"]="  Deploying Kitty config..."
  ["deploy_swaync"]="  Deploying Swaync config..."
  ["deploy_fuzzel"]="  Deploying Fuzzel config..."
  ["deploy_starship"]="  Deploying Starship config..."
  ["deploy_qs"]="  Setting up Quickshell..."
  ["deploy_tmux"]="  Setting up Tmux..."
  ["deploy_bashrc"]="  Updating .bashrc..."
  ["deploy_perm"]="  Setting script permissions..."
  ["deploy_systemd_save"]="  Setting up systemd session-save service..."
  ["deploy_hyprctl_exit"]="  Creating hyprctl-exit wrapper script..."
  ["deploy_plasma_autostart"]="  Creating Plasma autostart entry..."
  ["deploy_plasma_shutdown"]="  Creating Plasma shutdown hook..."
  ["done"]="==> Installation complete!"
  ["restart"]="  Restart Hyprland or run 'quickshell' to start."
  ["manual_wall"]="  ⚠️  Set your wallpapers in: BottomBorder.qml, WallpaperPanel.qml"
  ["manual_icons"]="  ⚠️  Add custom icons to your wallpaper directory if needed."
  ["manual_xdg"]="  ⚠️  Verify XDG user dir names in MenuPanel.qml if paths differ."
  ["manual_pactl"]="  ⚠️  Ensure 'pactl' is available (install pipewire-pulse if per-app volume doesn't work)."
  ["manual_session"]="  ℹ️  Session restore saves/restores open windows via save-session.sh + restore-session.sh."
  ["already"]="  Already exists, skipping."
  ["created"]="  Created."
  ["copied"]="  Copied."
  ["skipped"]="  Skipped."
  ["backup"]="  Backup saved as:"
  ["yes"]="y"
  ["no"]="n"
  ["mkdir"]="  Creating directory:"
  ["symlink"]="  Symlink:"
  ["write"]="  Writing:"
  ["checking"]="  Checking hyprland.conf for exec-once quickshell..."
  ["found"]="  ✓ Found."
  ["added"]="  ✓ Added."
  ["select_lang"]="Select language / Seleccione idioma:"
)

MSG_ES=(
  ["title"]="==> Instalador de dotfiles Quickshell"
  ["detect"]="==> Detectando sistema..."
  ["distro"]="  Distribución:"
  ["pkgmgr"]="  Gestor de paquetes:"
  ["wayland"]="  Sesión Wayland:"
  ["pkg_list"]="==> Paquetes a instalar (requeridos)"
  ["pkg_opt"]="  Opcionales (se saltan si no se encuentran)"
  ["pkg_confirm"]="  ¿Proceder con la instalación de paquetes? [Y/n]"
  ["pkg_installing"]="==> Instalando paquetes..."
  ["pkg_skip"]="  Instalación de paquetes omitida."
  ["cfg_wallpaper"]="==> Directorio de wallpapers"
  ["cfg_wallpaper_desc"]="  Directorio donde se guardarán los wallpapers de los temas."
  ["cfg_wallpaper_default"]="  Por defecto:"
  ["cfg_enter"]="  Ingrese la ruta (o Enter para usar el default):"
  ["cfg_xdg"]="==> Idioma de los directorios de usuario (XDG)"
  ["cfg_xdg_desc"]="  MenuPanel.qml usa accesos directos a Documentos, Imágenes, Música, Descargas."
  ["cfg_xdg_opt_es"]="  1) Español  (Documentos, Imágenes, Música, Descargas)"
  ["cfg_xdg_opt_en"]="  2) Inglés    (Documents, Pictures, Music, Downloads)"
  ["cfg_xdg_opt_auto"]="  3) Auto-detectar según locale"
  ["cfg_xdg_ask"]="  Elija [1-3]:"
  ["cfg_xdg_es"]="  → Usando nombres en español"
  ["cfg_xdg_en"]="  → Usando nombres en inglés"
  ["cfg_xdg_auto"]="  → Auto-detectado:"
  ["cfg_hypr"]="==> Directorio de configuración de Hyprland"
  ["cfg_hypr_desc"]="  Donde van hyprland.conf, hyprpaper.conf y scripts."
  ["cfg_kitty"]="==> Directorio de configuración de Kitty"
  ["cfg_kitty_desc"]="  Donde van kitty.conf y los archivos de tema."
  ["cfg_swaync"]="==> Directorio de configuración de Swaync"
  ["cfg_swaync_desc"]="  Donde va la configuración del centro de notificaciones."
  ["cfg_fuzzel"]="==> Directorio de configuración de Fuzzel"
  ["cfg_fuzzel_desc"]="  Donde va la configuración del lanzador de aplicaciones."
  ["cfg_starship"]="==> Archivo de configuración de Starship"
  ["cfg_starship_desc"]="  Donde va la configuración del prompt del terminal."
  ["cfg_bashrc"]="==> Configuración del shell"
  ["cfg_bashrc_desc"]="  ¿Agregar aliases, starship y configuración de fzf a ~/.bashrc?"
  ["cfg_bashrc_ask"]="  ¿Proceder? [Y/n]"
  ["deploy"]="==> Desplegando archivos de configuración..."
  ["deploy_wall"]="  Copiando wallpapers..."
  ["deploy_hypr"]="  Instalando configuración de Hyprland..."
  ["deploy_kitty"]="  Instalando configuración de Kitty..."
  ["deploy_swaync"]="  Instalando configuración de Swaync..."
  ["deploy_fuzzel"]="  Instalando configuración de Fuzzel..."
  ["deploy_starship"]="  Instalando configuración de Starship..."
  ["deploy_qs"]="  Configurando Quickshell..."
  ["deploy_tmux"]="  Configurando Tmux..."
  ["deploy_bashrc"]="  Actualizando .bashrc..."
  ["deploy_perm"]="  Estableciendo permisos de scripts..."
  ["deploy_systemd_save"]="  Configurando servicio systemd de guardado de sesión..."
  ["deploy_hyprctl_exit"]="  Creando script hyprctl-exit..."
  ["deploy_plasma_autostart"]="  Creando entrada de autostart para Plasma..."
  ["deploy_plasma_shutdown"]="  Creando hook de apagado para Plasma..."
  ["done"]="==> Instalación completa!"
  ["restart"]="  Reinicie Hyprland o ejecute 'quickshell' para iniciar."
  ["manual_wall"]="  ⚠️  Elija wallpapers en: BottomBorder.qml, WallpaperPanel.qml"
  ["manual_icons"]="  ⚠️  Agregue iconos personalizados al directorio de wallpapers si es necesario."
  ["manual_xdg"]="  ⚠️  Verifique nombres XDG en MenuPanel.qml si las rutas difieren."
  ["manual_pactl"]="  ⚠️  Asegúrese de que 'pactl' esté disponible (instale pipewire-pulse si el volumen por app no funciona)."
  ["manual_session"]="  ℹ️  Restauración de sesión guarda/restaura ventanas abiertas via save-session.sh + restore-session.sh."
  ["already"]="  Ya existe, omitiendo."
  ["created"]="  Creado."
  ["copied"]="  Copiado."
  ["skipped"]="  Omitido."
  ["backup"]="  Backup guardado como:"
  ["yes"]="s"
  ["no"]="n"
  ["mkdir"]="  Creando directorio:"
  ["symlink"]="  Enlace simbólico:"
  ["write"]="  Escribiendo:"
  ["checking"]="  Verificando hyprland.conf para exec-once quickshell..."
  ["found"]="  ✓ Encontrado."
  ["added"]="  ✓ Agregado."
  ["select_lang"]="Seleccione idioma / Select language:"
)

# ═══════════════════════════════════════════════════════════════
# SYSTEM DETECTION
# ═══════════════════════════════════════════════════════════════

msg "detect"
echo ""

# Distro
if [ -f /etc/os-release ]; then
  DISTRO=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
  DISTRO_LIKE=$(grep -E "^ID_LIKE=" /etc/os-release | cut -d= -f2 | tr -d '"')
else
  DISTRO="unknown"
  DISTRO_LIKE=""
fi
echo "$(msg "distro") $DISTRO ($DISTRO_LIKE)"

# Package manager
PKGMGR=""
if command -v paru &>/dev/null; then
  PKGMGR="paru"
elif command -v yay &>/dev/null; then
  PKGMGR="yay"
elif command -v pacman &>/dev/null; then
  PKGMGR="pacman"
fi

if [ -z "$PKGMGR" ]; then
  echo "  ERROR: No supported package manager found (paru, yay, pacman)."
  echo "  This installer currently supports Arch-based distributions only."
  exit 1
fi
echo "$(msg "pkgmgr") $PKGMGR"

# Wayland check
if [ -n "$WAYLAND_DISPLAY" ]; then
  echo "$(msg "wayland") yes"
else
  echo "$(msg "wayland") no (not detected)"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════
# PACKAGE LISTS
# ═══════════════════════════════════════════════════════════════

REQUIRED_PKGS=(
  quickshell
  wireplumber
  pipewire-pulse
  bluez
  bluez-utils
  networkmanager
  swaync
  hyprland
  hyprpaper
  fuzzel
  kitty
  python
  jq
  curl
  socat
  udisks2
  zip
  unzip
  poppler-utils
  wl-clipboard
  cliphist
  snixembed
  playerctl
  pavucontrol
  brightnessctl
  rate-mirrors
  tmux
  flatpak
  xclip
  slurp
  wf-recorder
)

FONT_PKGS=(
  ttf-firacode-nerd
  ttf-jetbrains-mono-nerd
)

AUR_PKGS=(
  wl-clip-persist-git
)

SHELL_PKGS=(
  starship
  fzf
  bat
  eza
  ugrep
  expac
)

OPTIONAL_PKGS=(
  unrar
  p7zip
  catdoc
)

ALL_PKGS=("${REQUIRED_PKGS[@]}" "${FONT_PKGS[@]}" "${SHELL_PKGS[@]}" "${OPTIONAL_PKGS[@]}")

# ── Show what will be installed ──────────────────────────────

echo "$(msg "pkg_list")"
for p in "${REQUIRED_PKGS[@]}"; do
  echo "    - $p"
done
echo ""
for p in "${FONT_PKGS[@]}"; do
  echo "    - $p (font)"
done
echo ""
echo "  $(msg "pkg_opt"):"
for p in "${OPTIONAL_PKGS[@]}"; do
  echo "    - $p"
done
echo ""
echo "  Shell tools (recommended):"
for p in "${SHELL_PKGS[@]}"; do
  echo "    - $p"
done
echo ""

# ═══════════════════════════════════════════════════════════════
# PATH CONFIGURATION
# ═══════════════════════════════════════════════════════════════

# Defaults
DEF_WALLPAPER_DIR="$HOME/Wallpapers/Wallpaper-imagen"
DEF_CONFIG_BASE="$HOME/.config"
DEF_HYPR_DIR="$DEF_CONFIG_BASE/hypr"
DEF_KITTY_DIR="$DEF_CONFIG_BASE/kitty"
DEF_SWAYNC_DIR="$DEF_CONFIG_BASE/swaync"
DEF_FUZZEL_DIR="$DEF_CONFIG_BASE/fuzzel"
DEF_STARSHIP_FILE="$DEF_CONFIG_BASE/starship.toml"

echo "════════════════════════════════════════════════════════════"
echo ""

# Wallpaper directory
msg "cfg_wallpaper"
echo "  $(msg "cfg_wallpaper_desc")"
echo "  $(msg "cfg_wallpaper_default") $DEF_WALLPAPER_DIR"
prompt "cfg_enter"
read -r WALLPAPER_DIR
WALLPAPER_DIR="${WALLPAPER_DIR:-$DEF_WALLPAPER_DIR}"
echo "  → $WALLPAPER_DIR"
echo ""

# XDG user dirs language
msg "cfg_xdg"
echo "  $(msg "cfg_xdg_desc")"
echo "  $(msg "cfg_xdg_opt_es")"
echo "  $(msg "cfg_xdg_opt_en")"
echo "  $(msg "cfg_xdg_opt_auto")"
prompt "cfg_xdg_ask"
read -r XDG_CHOICE

case "$XDG_CHOICE" in
  1|es)
    XDG_DOC="Documentos"
    XDG_PIC="Imágenes"
    XDG_MUS="Música"
    XDG_DWN="Descargas"
    msg "cfg_xdg_es"
    ;;
  2|en)
    XDG_DOC="Documents"
    XDG_PIC="Pictures"
    XDG_MUS="Music"
    XDG_DWN="Downloads"
    msg "cfg_xdg_en"
    ;;
  *)
    LOCALE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
    if [ -f "$LOCALE_DIR" ]; then
      XDG_DOC=$(grep "XDG_DOCUMENTS_DIR" "$LOCALE_DIR" 2>/dev/null | cut -d= -f2 | tr -d '"' | xargs basename 2>/dev/null || echo "Documentos")
      XDG_PIC=$(grep "XDG_PICTURES_DIR" "$LOCALE_DIR" 2>/dev/null | cut -d= -f2 | tr -d '"' | xargs basename 2>/dev/null || echo "Imágenes")
      XDG_MUS=$(grep "XDG_MUSIC_DIR" "$LOCALE_DIR" 2>/dev/null | cut -d= -f2 | tr -d '"' | xargs basename 2>/dev/null || echo "Música")
      XDG_DWN=$(grep "XDG_DOWNLOAD_DIR" "$LOCALE_DIR" 2>/dev/null | cut -d= -f2 | tr -d '"' | xargs basename 2>/dev/null || echo "Descargas")
      echo "  $(msg "cfg_xdg_auto") $XDG_DOC, $XDG_PIC, $XDG_MUS, $XDG_DWN"
    else
      XDG_DOC="Documentos"
      XDG_PIC="Imágenes"
      XDG_MUS="Música"
      XDG_DWN="Descargas"
      echo "  $(msg "cfg_xdg_es") (default)"
    fi
    ;;
esac
echo ""

# Other config dirs
echo "$(msg "cfg_hypr")"
echo "  $(msg "cfg_hypr_desc")"
echo "  $(msg "cfg_wallpaper_default") $DEF_HYPR_DIR"
prompt "cfg_enter"
read -r HYPR_DIR
HYPR_DIR="${HYPR_DIR:-$DEF_HYPR_DIR}"
echo "  → $HYPR_DIR"
echo ""

echo "$(msg "cfg_kitty")"
echo "  $(msg "cfg_kitty_desc")"
echo "  $(msg "cfg_wallpaper_default") $DEF_KITTY_DIR"
prompt "cfg_enter"
read -r KITTY_DIR
KITTY_DIR="${KITTY_DIR:-$DEF_KITTY_DIR}"
echo "  → $KITTY_DIR"
echo ""

echo "$(msg "cfg_swaync")"
echo "  $(msg "cfg_swaync_desc")"
echo "  $(msg "cfg_wallpaper_default") $DEF_SWAYNC_DIR"
prompt "cfg_enter"
read -r SWAYNC_DIR
SWAYNC_DIR="${SWAYNC_DIR:-$DEF_SWAYNC_DIR}"
echo "  → $SWAYNC_DIR"
echo ""

echo "$(msg "cfg_fuzzel")"
echo "  $(msg "cfg_fuzzel_desc")"
echo "  $(msg "cfg_wallpaper_default") $DEF_FUZZEL_DIR"
prompt "cfg_enter"
read -r FUZZEL_DIR
FUZZEL_DIR="${FUZZEL_DIR:-$DEF_FUZZEL_DIR}"
echo "  → $FUZZEL_DIR"
echo ""

echo "$(msg "cfg_starship")"
echo "  $(msg "cfg_starship_desc")"
echo "  $(msg "cfg_wallpaper_default") $DEF_STARSHIP_FILE"
prompt "cfg_enter"
read -r STARSHIP_FILE
STARSHIP_FILE="${STARSHIP_FILE:-$DEF_STARSHIP_FILE}"
echo "  → $STARSHIP_FILE"
echo ""

echo "$(msg "cfg_bashrc")"
echo "  $(msg "cfg_bashrc_desc")"
prompt "cfg_bashrc_ask"
read -r BASHRC_CHOICE
case "$BASHRC_CHOICE" in
  n|N|no|NO) INSTALL_BASHRC=false ;;
  *) INSTALL_BASHRC=true ;;
esac
echo ""

echo "════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════
# PACKAGE INSTALLATION
# ═══════════════════════════════════════════════════════════════

prompt "pkg_confirm"
read -r PKG_CONFIRM
echo ""

case "$PKG_CONFIRM" in
  n|N|no|NO)
    msg "pkg_skip"
    ;;
  *)
    msg "pkg_installing"

    "$PKGMGR" -S --needed --noconfirm "${REQUIRED_PKGS[@]}" "${FONT_PKGS[@]}" 2>&1 | tail -5

    for p in "${OPTIONAL_PKGS[@]}"; do
      if "$PKGMGR" -Si "$p" &>/dev/null; then
        "$PKGMGR" -S --needed --noconfirm "$p" 2>&1 | tail -1
      else
        echo "  (optional) $p not found in repos, skipping."
      fi
    done

    echo "  Installing shell tools..."
    for p in "${SHELL_PKGS[@]}"; do
      if "$PKGMGR" -Si "$p" &>/dev/null; then
        "$PKGMGR" -S --needed --noconfirm "$p" 2>&1 | tail -1
      else
        echo "  (shell) $p not found, skipping."
      fi
    done

    echo ""
    echo "  Installing AUR packages..."
    for p in "${AUR_PKGS[@]}"; do
      if "$PKGMGR" -Si "$p" &>/dev/null 2>&1; then
        "$PKGMGR" -S --needed --noconfirm "$p" 2>&1 | tail -1
      else
        echo "  (AUR) $p not found, you may need to install it manually."
      fi
    done
    ;;
esac

echo ""

# ═══════════════════════════════════════════════════════════════
# DEPLOY
# ═══════════════════════════════════════════════════════════════

msg "deploy"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# ── 1. Wallpapers ────────────────────────────────────────────

msg "deploy_wall"
if [ ! -d "$WALLPAPER_DIR" ]; then
  mkdir -p "$WALLPAPER_DIR"
  echo "  $(msg "mkdir") $WALLPAPER_DIR"
fi
if [ -f "$DOTFILES_DIR/wallpapers/darktheme.jpg" ] && [ ! -f "$WALLPAPER_DIR/darktheme.jpg" ]; then
  cp "$DOTFILES_DIR/wallpapers/"* "$WALLPAPER_DIR/"
  echo "  $(msg "copied") wallpapers → $WALLPAPER_DIR"
else
  echo "  $(msg "already")"
fi
echo ""

# ── 2. Hyprland ──────────────────────────────────────────────

msg "deploy_hypr"
mkdir -p "$HYPR_DIR"
mkdir -p "$HYPR_DIR/scripts"

deploy_file() {
  local src="$1"
  local dst="$2"
  if [ -f "$dst" ] && [ ! -f "$dst.bak" ]; then
    cp "$dst" "$dst.bak"
    echo "  $(msg "backup") $dst.bak"
  fi
  cp "$src" "$dst"
  echo "  $(msg "write") $dst"
}

# hyprland.conf — substitute $HOME with actual value
sed "s|\$HOME|$HOME|g" "$DOTFILES_DIR/hypr/hyprland.conf" > /tmp/qs_hyprland.conf
deploy_file /tmp/qs_hyprland.conf "$HYPR_DIR/hyprland.conf"

# hyprpaper.conf — substitute the wallpaper dir
sed "s|__WALLPAPER_DIR__|$WALLPAPER_DIR|g" "$DOTFILES_DIR/hypr/hyprpaper.conf" > /tmp/qs_hyprpaper.conf
deploy_file /tmp/qs_hyprpaper.conf "$HYPR_DIR/hyprpaper.conf"

# Scripts
deploy_file "$DOTFILES_DIR/hypr/scripts/toggle-minimize.sh" "$HYPR_DIR/scripts/toggle-minimize.sh"
deploy_file "$DOTFILES_DIR/hypr/scripts/minimize-window.sh" "$HYPR_DIR/scripts/minimize-window.sh"
chmod +x "$HYPR_DIR/scripts/"*.sh
echo ""

# ── 3. Kitty ─────────────────────────────────────────────────

msg "deploy_kitty"
mkdir -p "$KITTY_DIR"
deploy_file "$DOTFILES_DIR/kitty/kitty.conf" "$KITTY_DIR/kitty.conf"
deploy_file "$DOTFILES_DIR/kitty/gruvbox-dark.conf" "$KITTY_DIR/gruvbox-dark.conf"
deploy_file "$DOTFILES_DIR/kitty/gruvbox-light.conf" "$KITTY_DIR/gruvbox-light.conf"
echo ""

# ── 4. Swaync ────────────────────────────────────────────────

msg "deploy_swaync"
mkdir -p "$SWAYNC_DIR"
deploy_file "$DOTFILES_DIR/swaync/config.json" "$SWAYNC_DIR/config.json"
echo ""

# ── 5. Fuzzel ────────────────────────────────────────────────

msg "deploy_fuzzel"
mkdir -p "$FUZZEL_DIR"
deploy_file "$DOTFILES_DIR/fuzzel/fuzzel.ini" "$FUZZEL_DIR/fuzzel.ini"
echo ""

# ── 6. Starship ──────────────────────────────────────────────

msg "deploy_starship"
mkdir -p "$(dirname "$STARSHIP_FILE")"
deploy_file "$DOTFILES_DIR/starship/starship.toml" "$STARSHIP_FILE"
echo ""

# ── 7. Quickshell ────────────────────────────────────────────

msg "deploy_qs"
QS_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"

if [ -L "$QS_TARGET" ] && [ "$(readlink "$QS_TARGET")" = "$SCRIPT_DIR" ]; then
  echo "  $(msg "symlink") $QS_TARGET → $SCRIPT_DIR $(msg "already")"
elif [ -L "$QS_TARGET" ]; then
  ln -sf "$SCRIPT_DIR" "$QS_TARGET"
  echo "  $(msg "symlink") $QS_TARGET → $SCRIPT_DIR"
elif [ -d "$QS_TARGET" ]; then
  echo "  $QS_TARGET exists and is not a symlink. Skipping."
  echo "  To use this repo as config, remove it and re-run."
else
  ln -s "$SCRIPT_DIR" "$QS_TARGET"
  echo "  $(msg "symlink") $QS_TARGET → $SCRIPT_DIR"
fi

# Cache dir
CACHE_DIR="$HOME/.cache/quickshell"
if [ ! -d "$CACHE_DIR" ]; then
  mkdir -p "$CACHE_DIR"
  echo "  $(msg "mkdir") $CACHE_DIR"
fi
echo ""

# ── 8. Tmux ──────────────────────────────────────────────────

msg "deploy_tmux"
TMUX_DIR="$DEF_CONFIG_BASE/tmux"
mkdir -p "$TMUX_DIR"
deploy_file "$DOTFILES_DIR/tmux/tmux.conf" "$TMUX_DIR/tmux.conf"

# Install TPM if not present
TPM_DIR="$TMUX_DIR/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>/dev/null || true
  echo "  ✓ TPM installed"
else
  echo "  $(msg "already") TPM"
fi

# Install plugins via TPM
if [ -d "$TPM_DIR" ]; then
  "$TPM_DIR/bin/install_plugins" &>/dev/null || true
  echo "  ✓ Tmux plugins installed"
fi
echo ""

# ── 9. .bashrc ───────────────────────────────────────────────

if [ "$INSTALL_BASHRC" = true ]; then
  msg "deploy_bashrc"
  BASHRC="$HOME/.bashrc"
  if [ -f "$BASHRC" ] && ! grep -q "STARSHIP_AUTOSETUP" "$BASHRC" 2>/dev/null; then
    cp "$BASHRC" "$BASHRC.bak"
    echo "  $(msg "backup") $BASHRC.bak"
  fi

  if ! grep -q "STARSHIP_AUTOSETUP" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" << 'BASHRC_EOF'

# ── Quickshell dotfiles setup (added by install.sh) ──
# STARSHIP_AUTOSETUP
export PATH="$HOME/.local/bin:$PATH"

if [[ -x /usr/bin/eza ]]; then
  alias ls='eza -al --icons --git --group-directories-first'
  alias la='eza -a --icons --group-directories-first'
  alias ll='eza -l --icons --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
  alias l.='eza -ald --icons .*'
fi
if [[ -x /usr/bin/bat ]]; then
  alias cat='bat --style=header --style=snip --style=changes'
fi
alias grubup="sudo update-grub"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias grep='ugrep --color=auto'
alias fgrep='ugrep -F --color=auto'
alias egrep='ugrep -E --color=auto'

alias big="expac -H M '%m\t%n' | sort -h | nl"
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'
alias jctl="journalctl -p 3 -xb"
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

if [[ -f /usr/share/fzf/key-bindings.bash ]]; then
  source /usr/share/fzf/key-bindings.bash
fi
if [[ -f /usr/share/fzf/completion.bash ]]; then
  source /usr/share/fzf/completion.bash
fi

export FZF_CTRL_T_OPTS="--preview 'if [ -d {} ]; then eza --tree --color=always --icons {}; else bat --style=numbers --color=always --line-range :500 {}; fi'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --icons {} | head -200'"

# ── Tmux auto-start ──
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ "$TERM" != "dumb" ]; then
    tmux new-session -A -s "main-\$\$"
fi
BASHRC_EOF
    echo "  $(msg "write") $BASHRC (appended)"
  else
    echo "  $(msg "already")"
  fi
  echo ""
fi

# ── 10. Permissions ──────────────────────────────────────────

msg "deploy_perm"
chmod +x "$SCRIPT_DIR"/*.py 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/scripts/* 2>/dev/null || true
echo "  $(msg "copied")"
echo ""

# ── 11. Systemd user service ────────────────────────────────

msg "deploy_systemd_save"
SYSTEMD_USER_DIR="$DEF_CONFIG_BASE/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"
SERVICE_SRC="$DOTFILES_DIR/systemd/hyprland-session-save.service"
SERVICE_DST="$SYSTEMD_USER_DIR/hyprland-session-save.service"
if [ ! -f "$SERVICE_DST" ]; then
  deploy_file "$SERVICE_SRC" "$SERVICE_DST"
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable hyprland-session-save.service 2>/dev/null || true
  echo "  ✓ Systemd service enabled"
else
  echo "  $(msg "already")"
fi
echo ""

# ── 12. hyprctl-exit wrapper ────────────────────────────────

msg "deploy_hyprctl_exit"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
EXIT_SRC="$DOTFILES_DIR/local-bin/hyprctl-exit"
EXIT_DST="$LOCAL_BIN/hyprctl-exit"
if [ ! -f "$EXIT_DST" ]; then
  deploy_file "$EXIT_SRC" "$EXIT_DST"
  chmod +x "$EXIT_DST"
  echo "  ✓ hyprctl-exit created"
else
  echo "  $(msg "already")"
fi
echo ""

# ── 13. Plasma autostart ─────────────────────────────────────

msg "deploy_plasma_autostart"
AUTOSTART_DIR="$DEF_CONFIG_BASE/autostart"
mkdir -p "$AUTOSTART_DIR"
AUTOSTART_SRC="$DOTFILES_DIR/autostart/restore-session.desktop"
AUTOSTART_DST="$AUTOSTART_DIR/restore-session.desktop"
if [ ! -f "$AUTOSTART_DST" ]; then
  deploy_file "$AUTOSTART_SRC" "$AUTOSTART_DST"
  echo "  ✓ Plasma autostart created"
else
  echo "  $(msg "already")"
fi
echo ""

# ── 14. Plasma shutdown hook ─────────────────────────────────

msg "deploy_plasma_shutdown"
SHUTDOWN_DIR="$DEF_CONFIG_BASE/plasma-workspace/shutdown"
mkdir -p "$SHUTDOWN_DIR"
SHUTDOWN_SRC="$DOTFILES_DIR/plasma-shutdown/save-session.sh"
SHUTDOWN_DST="$SHUTDOWN_DIR/save-session.sh"
if [ ! -f "$SHUTDOWN_DST" ]; then
  deploy_file "$SHUTDOWN_SRC" "$SHUTDOWN_DST"
  chmod +x "$SHUTDOWN_DST"
  echo "  ✓ Plasma shutdown hook created"
else
  echo "  $(msg "already")"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# HYPRLAND AUTO-CONFIG
# ═══════════════════════════════════════════════════════════════

msg "checking"
if grep -q "exec-once.*quickshell" "$HYPR_DIR/hyprland.conf" 2>/dev/null; then
  msg "found"
else
  echo "" >> "$HYPR_DIR/hyprland.conf"
  echo "exec-once = quickshell --no-detailed-logs" >> "$HYPR_DIR/hyprland.conf"
  msg "added"
fi

# Also ensure hyprpaper exec-once
if ! grep -q "exec-once.*hyprpaper" "$HYPR_DIR/hyprland.conf" 2>/dev/null; then
  echo "exec-once = hyprpaper" >> "$HYPR_DIR/hyprland.conf"
  echo "  ✓ exec-once hyprpaper added."
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════"
msg "done"
echo ""
msg "restart"
echo ""
echo "  Config directories:"
echo "    Hyprland:  $HYPR_DIR"
echo "    Kitty:     $KITTY_DIR"
echo "    Swaync:    $SWAYNC_DIR"
echo "    Fuzzel:    $FUZZEL_DIR"
echo "    Starship:  $STARSHIP_FILE"
echo "    Wallpaper: $WALLPAPER_DIR"
echo "    Quickshell: $QS_TARGET → $SCRIPT_DIR"
echo "    Tmux:      $TMUX_DIR"
echo ""
msg "manual_wall"
msg "manual_icons"
msg "manual_xdg"
msg "manual_pactl"
  msg "manual_session"
  echo "  ℹ️  AUR package 'wl-clip-persist-git' was installed if found. If not, install manually: paru -S wl-clip-persist-git"

if [ "$XDG_DOC" != "Documentos" ] || [ "$XDG_PIC" != "Imágenes" ] || [ "$XDG_MUS" != "Música" ] || [ "$XDG_DWN" != "Descargas" ]; then
  echo "  ℹ️  XDG dirs set to: $XDG_DOC, $XDG_PIC, $XDG_MUS, $XDG_DWN"
  echo "     If MenuPanel.qml shortcuts don't match, edit lines 228-231."
fi
echo ""
echo "════════════════════════════════════════════════════════════"
