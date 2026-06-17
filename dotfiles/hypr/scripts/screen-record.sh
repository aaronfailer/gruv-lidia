#!/bin/bash
LOCKFILE="/tmp/screen-recording.lock"
OUTDIR="$HOME/Vídeos/Videocapturas de pantalla"
mkdir -p "$OUTDIR"

if [ -f "$LOCKFILE" ]; then
    kill "$(cat "$LOCKFILE")" 2>/dev/null
    rm -f "$LOCKFILE"
    notify-send "⏹ Grabación detenida" "Video guardado en $OUTDIR"
else
    FILE="$OUTDIR/recording-$(date +%Y%m%d-%H%M%S).mp4"
    GEOM=$(slurp)
    wf-recorder -g "$GEOM" -f "$FILE" -c libx264 -p yuv420p -r 60 &
    echo $! > "$LOCKFILE"
    notify-send "⏺ Grabando..." "SUPER+R para detener | Click en el indicador rojo"
fi
