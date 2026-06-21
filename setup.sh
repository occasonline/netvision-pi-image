#!/usr/bin/env bash
# ============================================================
# NetVisionConnect — configuration exécutée DANS l'image (chroot) par pimod.
# Regroupe toute la logique shell ici (au lieu de multiples lignes RUN),
# car pimod exécute les RUN sans shell : les préfixes d'env, les "||",
# les redirections ne marchent pas en RUN direct. Ici, on a un vrai shell.
# ============================================================
set -e
export DEBIAN_FRONTEND=noninteractive

echo "== Installation des paquets =="
apt-get update
apt-get install -y --no-install-recommends \
  xserver-xorg xinit x11-xserver-utils openbox unclutter ca-certificates \
  fonts-dejavu-core plymouth plymouth-themes watchdog
# Navigateur : chromium-browser (Pi OS) ou chromium (Debian)
apt-get install -y --no-install-recommends chromium-browser \
  || apt-get install -y --no-install-recommends chromium

echo "== Utilisateur kiosk =="
id kiosk >/dev/null 2>&1 || useradd -m -s /bin/bash kiosk
usermod -aG video,tty,input,render kiosk || true
printf 'allowed_users=anybody\nneeds_root_rights=yes\n' > /etc/X11/Xwrapper.config

echo "== Fichiers du kiosque =="
cp /opt/netvision/home/.bash_profile /home/kiosk/.bash_profile
cp /opt/netvision/home/.xinitrc      /home/kiosk/.xinitrc
chown -R kiosk:kiosk /home/kiosk

echo "== Autologin console =="
mkdir -p /etc/systemd/system/getty@tty1.service.d
cp /opt/netvision/autologin.conf /etc/systemd/system/getty@tty1.service.d/autologin.conf

echo "== Splash =="
mkdir -p /usr/share/plymouth/themes/netvision
cp -r /opt/netvision/theme/. /usr/share/plymouth/themes/netvision/
plymouth-set-default-theme netvision || true

echo "== Services =="
systemctl set-default multi-user.target
systemctl enable netvision-firstboot.service
systemctl enable getty@tty1.service
systemctl enable watchdog.service

echo "== Réglages de boot =="
B=/boot/firmware; [ -f "$B/config.txt" ] || B=/boot
grep -q '^dtparam=watchdog=on' "$B/config.txt" || echo 'dtparam=watchdog=on' >> "$B/config.txt"
grep -q '^disable_splash=1' "$B/config.txt" || echo 'disable_splash=1' >> "$B/config.txt"
grep -q 'plymouth.ignore-serial-consoles' "$B/cmdline.txt" \
  || sed -i 's/$/ quiet splash plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0/' "$B/cmdline.txt"
update-initramfs -u || true

echo "== Setup terminé =="
