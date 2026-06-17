#!/bin/bash

echo "========================================"
echo "   LIMPIEZA DEL SISTEMA"
echo "========================================"

echo ""
echo ">>> Limpiando caché de pacman (manteniendo 1 versión)..."
sudo paccache -rk1 2>/dev/null
echo "✓  Caché de pacman limpiado"

echo ""
echo ">>> Eliminando dependencias huérfanas..."
ORPHANS=$(pacman -Qtdq 2>/dev/null)
if [ -n "$ORPHANS" ]; then
    sudo pacman -Rns $ORPHANS --noconfirm 2>&1
else
    echo "✓  No hay dependencias huérfanas"
fi

echo ""
echo ">>> Limpiando caché de paru..."
paru -c --noconfirm 2>/dev/null || echo "(no aplica)"

echo ""
echo ">>> Limpiando flatpak no utilizado..."
flatpak uninstall --unused -y 2>&1

echo ""
echo ">>> Limpiando caches específicos de usuario..."
rm -rf "$HOME/.cache/yay/"* 2>/dev/null
rm -rf "$HOME/.cache/paru/"* 2>/dev/null
rm -rf "$HOME/.cache/pip/"* 2>/dev/null
rm -rf "$HOME/.cache/npm/"* 2>/dev/null
rm -rf "$HOME/.cache/go/build/"* 2>/dev/null
find "$HOME/.cache/thumbnails" -type f -atime +30 -delete 2>/dev/null
find "$HOME/.cache" -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null
echo "✓  Caches específicos limpiados (se preservó hyprland-session.json)"

echo ""
echo ">>> Limpiando logs del sistema (journal)..."
sudo journalctl --vacuum-size=100M 2>&1

echo ""
echo "========================================"
echo "   LIMPIEZA COMPLETA"
echo "========================================"

echo ""
echo "Espacio disponible en disco:"
df -h / | awk 'NR==2 {print "  " $3 " usado de " $2 " (" $5 ")"}'
echo ""
echo "Presiona Enter para cerrar..."
read -r

