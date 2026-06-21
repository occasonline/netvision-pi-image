#!/bin/bash
# ============================================================
# NetVisionConnect — allumage/extinction de la TV via HDMI-CEC.
# Usage : netvision-screen.sh on|off
# (La TV doit avoir le CEC activé — chez TCL : « T-Link ».)
# ============================================================
CEC="cec-client -s -d 1"
case "$1" in
  on)  echo 'on 0'      | $CEC >/dev/null 2>&1 ;;
  off) echo 'standby 0' | $CEC >/dev/null 2>&1 ;;
  *)   echo "Usage: netvision-screen.sh on|off" ;;
esac
