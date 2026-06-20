#!/bin/bash
# ============================================================
# NetVisionConnect — premier démarrage
# Dépose les fichiers de config (url, orientation) sur la partition
# de boot (FAT) pour qu'ils soient modifiables depuis n'importe quel PC.
# ============================================================
set +e

BOOT=/boot/firmware/netvision
[ -d /boot/firmware ] || BOOT=/boot/netvision

mkdir -p "$BOOT"
[ -f "$BOOT/url.txt" ]         || cp /opt/netvision/defaults/url.txt         "$BOOT/url.txt"
[ -f "$BOOT/orientation.txt" ] || cp /opt/netvision/defaults/orientation.txt "$BOOT/orientation.txt"

exit 0
