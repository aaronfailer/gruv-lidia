#!/bin/bash

echo "========================================"
echo "   VERIFICACIÓN PREVIA DEL SISTEMA"
echo "========================================"

echo ""
echo ">>> Verificando integridad de paquetes..."
sudo pacman -Qk 2>/dev/null | grep "missing file" > /tmp/qs_pre_check.txt || true
if [ -s /tmp/qs_pre_check.txt ]; then
    echo "⚠  Paquetes con archivos faltantes detectados:"
    cat /tmp/qs_pre_check.txt
    echo ""
    echo "¿Continuar de todas formas? (s/n)"
    read -r resp
    if [ "$resp" != "s" ]; then
        echo "Actualización cancelada."
        exit 1
    fi
else
    echo "✓  No se detectaron problemas de integridad"
fi

echo ""
echo ">>> Verificando base de datos de pacman..."
sudo pacman -Dk 2>&1 | tail -5 || echo "(no critical errors)"

echo ""
echo ">>> Verificando dependencias huérfanas..."
ORPHANS=$(pacman -Qtdq 2>/dev/null)
if [ -n "$ORPHANS" ]; then
    echo "Dependencias huérfanas encontradas:"
    echo "$ORPHANS"
else
    echo "✓  Sin dependencias huérfanas"
fi

echo ""
echo "========================================"
echo "   ACTUALIZANDO PACMAN"
echo "========================================"
sudo pacman -Syu --noconfirm

echo ""
echo "========================================"
echo "   ACTUALIZANDO AUR (PARU)"
echo "========================================"
paru -Syu --noconfirm

echo ""
echo "========================================"
echo "   ACTUALIZANDO FLATPAK"
echo "========================================"
flatpak update -y

echo ""
echo "========================================"
echo "   VERIFICACIÓN POST-ACTUALIZACIÓN"
echo "========================================"
echo ""

sudo pacman -Qk 2>/dev/null | grep "missing file" > /tmp/qs_post_check.txt || true
if [ -s /tmp/qs_post_check.txt ]; then
    echo "⚠  SE DETECTARON PAQUETES CON ARCHIVOS FALTANTES:"
    cat /tmp/qs_post_check.txt
    echo ""
    echo "Revisión recomendada: ejecutá 'sudo pacman -Syu --overwrite=\"*\"' si es un conflicto conocido."
else
    echo "✓  No se detectaron problemas post-actualización"
fi

echo ""
echo "========================================"
echo "   ACTUALIZACIÓN COMPLETA"
echo "========================================"

echo ""
echo "Presiona Enter para cerrar..."
read -r

