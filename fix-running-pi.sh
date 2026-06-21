#!/usr/bin/env bash
# ============================================================
# NetVisionConnect — correctif "à chaud" sur un Raspberry déjà démarré.
# Met en place le démarrage kiosque (autologin + startx) et corrige la
# boucle de login. À lancer directement sur le Pi.
#   curl -sL https://raw.githubusercontent.com/occasonline/netvision-pi-image/master/fix-running-pi.sh | sudo bash
# ============================================================
set -e
if [ "$(id -u)" -ne 0 ]; then echo "Lancez avec sudo."; exit 1; fi

# Utilisateur kiosque (créé si absent)
id kiosk >/dev/null 2>&1 || useradd -m -s /bin/bash kiosk
usermod -aG video,tty,input,render kiosk 2>/dev/null || true

# Script de lancement du kiosque (récupéré/mis à jour depuis le dépôt)
RAW="https://raw.githubusercontent.com/occasonline/netvision-pi-image/master/files/usr/local/bin/netvision-kiosk.sh"
wget -qO /usr/local/bin/netvision-kiosk.sh "$RAW" || curl -fsSL -o /usr/local/bin/netvision-kiosk.sh "$RAW"
chmod +x /usr/local/bin/netvision-kiosk.sh

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

echo ""
echo "✅ Correctif appliqué. Redémarrage dans 5 secondes…"
sleep 5
reboot
