#!/usr/bin/env bash
# ============================================================
# NetVisionConnect — correctif "à chaud" sur un Raspberry déjà démarré.
# Met en place le démarrage kiosque (autologin + startx) et corrige la
# boucle de login. À lancer directement sur le Pi.
#   curl -sL https://raw.githubusercontent.com/occasonline/netvision-pi-image/master/fix-running-pi.sh | sudo bash
# ============================================================
set -e
if [ "$(id -u)" -ne 0 ]; then echo "Lancez avec sudo."; exit 1; fi

# --- Installation des paquets nécessaires (idempotent) ---
export DEBIAN_FRONTEND=noninteractive
echo "== Installation des paquets (X, Chromium)… =="
apt-get update
apt-get install -y --no-install-recommends \
  xserver-xorg xinit x11-xserver-utils openbox unclutter ca-certificates fonts-dejavu-core \
  cec-utils feh plymouth plymouth-themes
apt-get install -y --no-install-recommends chromium \
  || apt-get install -y --no-install-recommends chromium-browser

# Utilisateur kiosque (créé si absent)
id kiosk >/dev/null 2>&1 || useradd -m -s /bin/bash kiosk
usermod -aG video,tty,input,render kiosk 2>/dev/null || true

# Script de lancement du kiosque (récupéré/mis à jour depuis le dépôt)
BASE="https://raw.githubusercontent.com/occasonline/netvision-pi-image/master/files"
wget -qO /usr/local/bin/netvision-kiosk.sh "$BASE/usr/local/bin/netvision-kiosk.sh" \
  || curl -fsSL -o /usr/local/bin/netvision-kiosk.sh "$BASE/usr/local/bin/netvision-kiosk.sh"
chmod +x /usr/local/bin/netvision-kiosk.sh

# Allumage/extinction programmés de l'écran (HDMI-CEC)
for f in netvision-screen.sh netvision-screen-tick.sh; do
  wget -qO "/usr/local/bin/$f" "$BASE/usr/local/bin/$f" \
    || curl -fsSL -o "/usr/local/bin/$f" "$BASE/usr/local/bin/$f"
  chmod +x "/usr/local/bin/$f"
done
cat > /etc/cron.d/netvision-screen <<'CRON'
SHELL=/bin/sh
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
* * * * * root /usr/local/bin/netvision-screen-tick.sh
@reboot root sleep 30 && /usr/local/bin/netvision-screen-tick.sh --enforce
CRON
chmod 644 /etc/cron.d/netvision-screen
# Horaire par défaut sur la carte SD (modifiable par écran), si absent
SCFG=/boot/firmware/netvision; [ -d /boot/firmware ] || SCFG=/boot/netvision
mkdir -p "$SCFG"
[ -f "$SCFG/schedule.txt" ] || wget -qO "$SCFG/schedule.txt" "$BASE/boot/netvision/schedule.txt" || true

# --- Branding NVC : logo de chargement (feh) + splash de boot (Plymouth) ---
LOGO_URL="https://raw.githubusercontent.com/occasonline/netvision-pi-image/master/assets/logo.png"
mkdir -p /usr/local/share/netvision /usr/share/plymouth/themes/netvision
wget -qO /usr/local/share/netvision/logo.png "$LOGO_URL" \
  || curl -fsSL -o /usr/local/share/netvision/logo.png "$LOGO_URL" || true
cp /usr/local/share/netvision/logo.png /usr/share/plymouth/themes/netvision/logo.png 2>/dev/null || true
for f in netvision.plymouth netvision.script; do
  wget -qO "/usr/share/plymouth/themes/netvision/$f" "$BASE/usr/share/plymouth/themes/netvision/$f" \
    || curl -fsSL -o "/usr/share/plymouth/themes/netvision/$f" "$BASE/usr/share/plymouth/themes/netvision/$f" || true
done
plymouth-set-default-theme netvision 2>/dev/null || true
BD=/boot/firmware; [ -f "$BD/cmdline.txt" ] || BD=/boot
grep -q 'splash' "$BD/cmdline.txt" \
  || sed -i 's/$/ quiet splash plymouth.ignore-serial-consoles logo.nologo/' "$BD/cmdline.txt"
update-initramfs -u 2>/dev/null || true

# Autoriser X pour un utilisateur non-root
printf 'allowed_users=anybody\nneeds_root_rights=yes\n' > /etc/X11/Xwrapper.config

# Connexion automatique de "kiosk" sur la console tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin kiosk --noclear %I $TERM
EOF

# Lancement de l'interface graphique au login de kiosk
cat > /home/kiosk/.bash_profile <<'EOF'
if [ "$(tty)" = "/dev/tty1" ] && [ -z "${DISPLAY:-}" ]; then
  while true; do startx -- -nocursor; sleep 3; done
fi
EOF
echo 'exec /usr/local/bin/netvision-kiosk.sh' > /home/kiosk/.xinitrc
chown -R kiosk:kiosk /home/kiosk

# Désactive l'ancien service qui provoquait la boucle de login
systemctl disable netvision-kiosk.service 2>/dev/null || true
systemctl set-default multi-user.target

# Forcer le 1080p au démarrage (la 4K surcharge le rendu navigateur → demi-écran)
BOOTDIR=/boot/firmware; [ -f "$BOOTDIR/cmdline.txt" ] || BOOTDIR=/boot
grep -q 'video=HDMI' "$BOOTDIR/cmdline.txt" \
  || sed -i 's/$/ video=HDMI-A-1:1920x1080@60/' "$BOOTDIR/cmdline.txt"
grep -q '^disable_overscan' "$BOOTDIR/config.txt" 2>/dev/null \
  || echo 'disable_overscan=1' >> "$BOOTDIR/config.txt"

echo ""
echo "✅ Correctif appliqué. Redémarrage dans 5 secondes…"
sleep 5
reboot
