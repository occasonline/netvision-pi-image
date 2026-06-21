#!/bin/bash
# ============================================================
# NetVisionConnect — Démarrage du kiosque (Chromium plein écran)
# Lit l'URL et l'orientation depuis la partition de boot, applique
# la rotation, désactive la veille, et relance Chromium s'il tombe.
# ============================================================
set +e

# Dossier de configuration sur la partition de boot (modifiable depuis n'importe quel PC)
BOOT_CFG=/boot/firmware/netvision
[ -d "$BOOT_CFG" ] || BOOT_CFG=/boot/netvision   # compatibilité anciennes versions de Raspberry Pi OS

# --- URL du player ---
URL="https://app.netvisionconnect.com/?player=true"
if [ -f "$BOOT_CFG/url.txt" ]; then
  CFG_URL="$(grep -v '^#' "$BOOT_CFG/url.txt" | tr -d '[:space:]')"
  [ -n "$CFG_URL" ] && URL="$CFG_URL"
fi

# --- Orientation ---
ORIENT=landscape
if [ -f "$BOOT_CFG/orientation.txt" ]; then
  CFG_O="$(grep -v '^#' "$BOOT_CFG/orientation.txt" | tr -d '[:space:]')"
  [ -n "$CFG_O" ] && ORIENT="$CFG_O"
fi
case "$ORIENT" in
  portrait|portrait-left|left)   ROT=left ;;
  portrait-right|right)          ROT=right ;;
  inverted|180|upside-down)      ROT=inverted ;;
  *)                             ROT=normal ;;
esac

# --- Résolution forcée (Full HD par défaut, idéal signage ; surchargeable) ---
RES=1920x1080
if [ -f "$BOOT_CFG/resolution.txt" ]; then
  CFG_R="$(grep -v '^#' "$BOOT_CFG/resolution.txt" | tr -d '[:space:]')"
  [ -n "$CFG_R" ] && RES="$CFG_R"
fi

# --- Détecte la sortie connectée, force la résolution et applique la rotation ---
OUTPUT="$(xrandr --query | awk '/ connected/{print $1; exit}')"
if [ -n "$OUTPUT" ]; then
  xrandr --output "$OUTPUT" --mode "$RES" 2>/dev/null || true
  xrandr --output "$OUTPUT" --rotate "$ROT" 2>/dev/null || true
fi

# --- Pas de veille ni d'extinction d'écran ---
xset s off
xset -dpms
xset s noblank

# --- Masquer le curseur ---
unclutter -idle 0.1 -root &

# --- Visuel de marque NVC affiché pendant le chargement (avant Chromium) ---
if command -v feh >/dev/null 2>&1; then
  if [ -f /usr/local/share/netvision/splash.png ]; then
    feh --no-fehbg --image-bg "#1B3A6B" --bg-max /usr/local/share/netvision/splash.png 2>/dev/null || true
  elif [ -f /usr/local/share/netvision/logo.png ]; then
    feh --no-fehbg --image-bg "#1B3A6B" --bg-center /usr/local/share/netvision/logo.png 2>/dev/null || true
  fi
fi

# --- Évite la bulle "Restaurer les pages" après un redémarrage ---
PREF="$HOME/.config/chromium/Default/Preferences"
if [ -f "$PREF" ]; then
  sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]*"/"exit_type":"Normal"/' "$PREF" 2>/dev/null
fi

# --- Binaire Chromium (chromium-browser sur Pi OS, chromium sur Debian) ---
CHROME="$(command -v chromium-browser || command -v chromium || echo chromium)"

# --- Boucle de résilience : relance Chromium s'il se ferme ---
while true; do
  "$CHROME" \
    --kiosk "$URL" \
    --window-position=0,0 \
    --window-size=1920,1080 \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crash-bubble \
    --disable-features=Translate,TranslateUI,UseChromeOSDirectVideoDecoder \
    --enable-features=VaapiVideoDecoder \
    --use-gl=egl \
    --ignore-gpu-blocklist \
    --enable-gpu-rasterization \
    --enable-zero-copy \
    --no-first-run \
    --fast --fast-start \
    --autoplay-policy=no-user-gesture-required \
    --check-for-update-interval=31536000 \
    --overscroll-history-navigation=0 \
    --disable-pinch
  echo "[netvision-kiosk] Chromium s'est fermé, relance dans 3s…"
  sleep 3
done
