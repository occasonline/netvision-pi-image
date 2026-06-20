# NetVisionConnect — Image Raspberry Pi (kiosque)

Image système sur-mesure pour transformer un **Raspberry Pi 4 / 5** en lecteur
d'affichage NetVisionConnect — comme une « appliance » Yodeck, mais à vous.

Au démarrage, le Pi lance automatiquement **Chromium en plein écran** sur
`https://app.netvisionconnect.com/?player=true`, affiche son **code de jumelage**,
et vous le liez depuis l'admin. **Une seule image pour tous les écrans.**

## Ce que fait l'image

| Fonction | Détail |
|---|---|
| 🖥️ Kiosque plein écran | Chromium `--kiosk` sur l'URL du player, relancé automatiquement s'il tombe |
| 🎨 Branding au démarrage | Splash avec votre logo sur fond bleu nuit (pas de texte Linux) |
| 🌙 Reboot nocturne | Redémarrage automatique chaque nuit à 04:00 (purge mémoire) |
| 🛡️ Watchdog matériel | Redémarre le Pi s'il se fige |
| 💾 Lecture seule (option) | Protège la carte SD de l'usure (à activer après installation) |
| 🧭 Orientation par écran | Paysage / portrait, réglable par appareil sans re-flasher |
| 🔗 Jumelage natif | Chaque Pi affiche son code → vous le liez depuis l'admin |

> 🔑 **L'app reste pilotée par le cloud.** Quand vous mettez à jour
> `app.netvisionconnect.com`, tous les écrans reçoivent le nouveau code au
> rechargement — **sans re-flasher les cartes SD**. L'image OS reste stable.

## 1. Construire l'image (.img) — dans le cloud, sans Linux

Le dépôt contient un workflow GitHub Actions qui génère l'image automatiquement.

1. Poussez ce dossier dans un dépôt GitHub.
2. Onglet **Actions** → workflow **« Build NetVisionConnect Pi image »** → **Run workflow**.
3. À la fin (~15–25 min), téléchargez l'**artifact** `netvisionconnect-pi-image`
   (un fichier `netvisionconnect-pi-AAAAMMJJ.img.xz`).

> 💡 Le splash utilise `assets/logo.png` (déjà fourni). Remplacez-le par votre
> logo si besoin (PNG ~400px, fond transparent).

## 2. Graver sur la carte SD

- Avec **Raspberry Pi Imager** ou **balenaEtcher**.
- Choisissez le fichier `.img.xz` (pas besoin de le décompresser, les deux outils gèrent le `.xz`).
- Carte SD 16 Go recommandée (qualité « endurance » de préférence pour le 24/7).

## 3. Premier démarrage & jumelage

1. Insérez la carte, branchez l'écran et le réseau (Ethernet conseillé), allumez.
2. Après le splash, l'écran affiche un **code de jumelage**.
3. Dans l'admin NetVisionConnect → **Écrans** → saisissez ce code.
4. L'écran bascule sur le contenu. ✅

## 4. Régler l'orientation (par écran)

Sur un PC, ouvrez la carte SD (partition `bootfs`/`boot`) → dossier `netvision/`
→ éditez **`orientation.txt`** :

```
landscape        # paysage (défaut)
portrait         # portrait, rotation 90° à gauche
portrait-right   # portrait, rotation 90° à droite
inverted         # 180°
```

Vous pouvez aussi changer l'URL du player dans **`url.txt`**. Redémarrez l'écran après modification.

## 5. Activer la lecture seule (recommandé, après installation)

Une fois l'écran installé et jumelé, connectez-vous en SSH (ou clavier) et lancez :

```bash
netvision-readonly on
sudo reboot
```

La carte SD n'est alors plus écrite → durée de vie maximale. Pour modifier la
config ensuite : `netvision-readonly off`, modifiez, puis réactivez.

## Dépannage

- **Écran noir / pas de splash** : vérifiez l'alimentation (Pi 4/5 = 5V/3A officiel) et le câble HDMI (port HDMI0).
- **Reste sur le code de jumelage** : c'est normal tant qu'il n'est pas lié dans l'admin.
- **Logs du kiosque** : `journalctl -u netvision-kiosk -b`.
- Identifiants par défaut pour la maintenance : créez-les via Raspberry Pi Imager (réglages avancés) avant de graver, ou activez SSH.

---

Construit avec [pimod](https://github.com/Nature40/pimod) · Base : Raspberry Pi OS Lite (Bookworm arm64).
