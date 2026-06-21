# NetVisionConnect — lance l'affichage graphique automatiquement sur la console.
# Sur tty1, sans session X déjà active : démarre X (qui lance le kiosque).
if [ "$(tty)" = "/dev/tty1" ] && [ -z "${DISPLAY:-}" ]; then
  while true; do
    startx -- -nocursor
    sleep 3   # si X se ferme, on le relance (résilience)
  done
fi
