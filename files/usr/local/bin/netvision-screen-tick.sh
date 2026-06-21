#!/bin/bash
# ============================================================
# NetVisionConnect — allumage/extinction programmés de l'écran.
# Lit les horaires dans schedule.txt (sur la carte SD, par écran).
# Appelé chaque minute par cron ; gère aussi --enforce au démarrage.
# ============================================================
BOOT=/boot/firmware/netvision; [ -d "$BOOT" ] || BOOT=/boot/netvision
SCHED="$BOOT/schedule.txt"
[ -f "$SCHED" ] || exit 0

ON=$(grep -i '^ON='  "$SCHED" | cut -d= -f2 | tr -d '[:space:]')
OFF=$(grep -i '^OFF=' "$SCHED" | cut -d= -f2 | tr -d '[:space:]')
# Si l'un des deux est vide → planification désactivée (écran toujours allumé)
{ [ -z "$ON" ] || [ -z "$OFF" ]; } && exit 0

NOW=$(date +%H:%M)

# Est-on dans la plage allumée [ON, OFF[ ? (gère le passage par minuit)
within() {
  if [ "$ON" \< "$OFF" ]; then
    [ ! "$NOW" \< "$ON" ] && [ "$NOW" \< "$OFF" ]
  else
    [ ! "$NOW" \< "$ON" ] || [ "$NOW" \< "$OFF" ]
  fi
}

# Mode --enforce (au démarrage) : met l'écran dans le bon état tout de suite
if [ "$1" = "--enforce" ]; then
  if within; then /usr/local/bin/netvision-screen.sh on; else /usr/local/bin/netvision-screen.sh off; fi
  exit 0
fi

# Mode normal (cron chaque minute) : agit aux transitions
[ "$NOW" = "$ON" ]  && /usr/local/bin/netvision-screen.sh on
[ "$NOW" = "$OFF" ] && /usr/local/bin/netvision-screen.sh off
exit 0
