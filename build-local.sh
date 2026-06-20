#!/usr/bin/env bash
# ============================================================
# NetVisionConnect — construction de l'image Pi sur une machine
# Linux x86_64 (VPS Hostinger, ou WSL2). Émule l'ARM via qemu.
# Usage : sudo bash build-local.sh
# Prérequis : Debian/Ubuntu (apt), KVM (pas OpenVZ), ~10 Go libres.
# ============================================================
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Lancez avec sudo :  sudo bash build-local.sh"
  exit 1
fi

cd "$(dirname "$0")"

echo "==> 1/5 Installation des dépendances"
apt-get update -y
apt-get install -y git curl wget xz-utils unzip kpartx qemu-user-static binfmt-support \
  parted file fdisk units rsync dosfstools e2fsprogs

echo "==> 2/5 Récupération de pimod"
if [ ! -d /opt/pimod ]; then
  git clone --depth 1 https://github.com/Nature40/pimod.git /opt/pimod
fi

echo "==> 3/5 Téléchargement de Raspberry Pi OS Lite (arm64)"
if [ ! -f raspios-lite.img ]; then
  curl -L -o raspios.img.xz "https://downloads.raspberrypi.com/raspios_lite_arm64_latest"
  xz -d -T0 raspios.img.xz
  mv raspios*.img raspios-lite.img
fi

echo "==> 4/5 Préparation du logo de démarrage"
cp -f assets/logo.png files/usr/share/plymouth/themes/netvision/logo.png

echo "==> 5/5 Construction de l'image (20-40 min selon le VPS)…"
/opt/pimod/pimod.sh Pifile

OUT="netvisionconnect-pi-$(date +%Y%m%d).img"
mv raspios-lite.img "$OUT"
echo "==> Compression de $OUT…"
xz -T0 -9 "$OUT"

echo ""
echo "✅ TERMINÉ : $(pwd)/$OUT.xz"
ls -lh "$OUT.xz"
echo "Récupérez ce fichier sur votre PC, puis gravez-le avec Raspberry Pi Imager / balenaEtcher."
