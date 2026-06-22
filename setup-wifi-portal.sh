#!/usr/bin/env bash
# ============================================================
# NetVisionConnect — Portail Wi-Fi (Comitup)
# Quand le Pi n'a pas de Wi-Fi connu, il crée un point d'accès
# « NetVision-<nnnn> ». L'installateur s'y connecte avec son
# téléphone et choisit le Wi-Fi du client + mot de passe via une
# page web. Idéal pour le déploiement chez les clients.
#
#   sudo bash setup-wifi-portal.sh
#
# ⚠️ À exécuter de préférence sur une carte DÉDIÉE aux clients :
#    l'installation reconfigure la gestion réseau (NetworkManager).
#    Flashez la carte SANS Wi-Fi dans Imager (Comitup gère le Wi-Fi).
# ============================================================
set -e
[ "$(id -u)" -eq 0 ] || { echo "Lancez avec sudo : sudo bash setup-wifi-portal.sh"; exit 1; }
export DEBIAN_FRONTEND=noninteractive

DEB_URL="https://davesteele.github.io/comitup/deb/davesteele-comitup-apt-source_1.3_all.deb"

echo "== Ajout du dépôt Comitup =="
curl -fsSL -o /tmp/comitup-apt.deb "$DEB_URL" || wget -qO /tmp/comitup-apt.deb "$DEB_URL"
dpkg -i --force-all /tmp/comitup-apt.deb
rm -f /tmp/comitup-apt.deb
apt-get update

echo "== Installation de Comitup (+ portail web) =="
apt-get install -y comitup comitup-web || apt-get install -y comitup

echo "== Nom du point d'accès de configuration =="
if [ -f /etc/comitup.conf ]; then
  sed -i 's|^[# ]*ap_name:.*|ap_name: NetVision-<nnnn>|' /etc/comitup.conf
  grep -q '^ap_name:' /etc/comitup.conf || echo 'ap_name: NetVision-<nnnn>' >> /etc/comitup.conf
fi

# Comitup gère le Wi-Fi via NetworkManager (défaut sur Raspberry Pi OS récent)
systemctl enable comitup 2>/dev/null || true

echo ""
echo "✅ Portail Wi-Fi installé. Redémarrez le Pi (sudo reboot)."
echo "   Sans Wi-Fi connu, il créera le hotspot « NetVision-<nnnn> » :"
echo "   connectez-vous-y au téléphone → une page s'ouvre → choisissez"
echo "   le Wi-Fi du client + mot de passe. C'est mémorisé pour la suite."
