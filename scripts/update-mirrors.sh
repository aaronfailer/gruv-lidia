#!/bin/bash

echo "========================================"
echo "   ACTUALIZANDO MIRRORS PARA ARGENTINA"
echo "========================================"
echo ""

echo "Mirrors actuales:"
echo "-----------------"
if [ -s /etc/pacman.d/mirrorlist ]; then
    grep "^Server" /etc/pacman.d/mirrorlist 2>/dev/null || echo "  (formato no reconocido)"
else
    echo "  (archivo vacío)"
fi
echo ""

if command -v rate-mirrors &>/dev/null; then
    echo "Analizando mirrors con rate-mirrors (priorizando países cercanos)..."
    echo ""
    rate-mirrors --entry-country AR --max-mirrors-to-output 20 arch 2>&1 | tee /tmp/qs_new_mirrors.txt
    if [ -s /tmp/qs_new_mirrors.txt ]; then
        grep "^Server" /tmp/qs_new_mirrors.txt | sudo tee /etc/pacman.d/mirrorlist > /dev/null
        sudo rm -f /etc/pacman.d/mirrorlist.pacnew 2>/dev/null
        echo ""
        echo "✓  Mirrors actualizados con rate-mirrors."
    else
        echo ""
        echo "⚠  rate-mirrors no generó mirrors, usando reflector..."
        sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        sudo rm -f /etc/pacman.d/mirrorlist.pacnew 2>/dev/null
    fi
elif command -v reflector &>/dev/null; then
    echo "Usando reflector..."
    sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    sudo rm -f /etc/pacman.d/mirrorlist.pacnew 2>/dev/null
else
    echo "Error: no se encontró ni rate-mirrors ni reflector."
    exit 1
fi

echo ""

if [ -s /etc/pacman.d/mirrorlist ]; then
    echo "Top 20 mirrors (ordenados por velocidad):"
    echo "----------------------------------------"
    grep -E "^#+\s+[0-9]+\." /tmp/qs_new_mirrors.txt 2>/dev/null | sed 's/^#\+\s*//' | head -20 | while read -r line; do
        num=$(echo "$line" | awk '{print $1}' | tr -d '.')
        country=$(echo "$line" | grep -oP '\[\K[A-Z]{2}(?=\])' || echo "??")
        speed=$(echo "$line" | grep -oP 'speed: \K[0-9.]+ [KM]B/s' || echo "?")
        url=$(echo "$line" | grep -oP -e '-> \K\S+' | sed 's|/archlinux/.*||' || echo "?")
        printf "  %2d. [%s] %10s  %s\n" "$num" "$country" "$speed" "$url"
    done
    echo ""
    echo "Mirrors guardados en /etc/pacman.d/mirrorlist: $(grep -c "^Server" /etc/pacman.d/mirrorlist) servidores"
else
    echo "⚠  No se pudo generar la lista de mirrors."
fi

echo ""
echo "Presiona Enter para cerrar..."
read -r


