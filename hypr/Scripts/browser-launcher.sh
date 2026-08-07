#!/bin/bash

for b in zen-browser brave-origin brave firefox vivaldi librewolf; do
  if command -v "$b" >/dev/null 2>&1; then
    exec "$b" "$@"
    exit 0
  fi
done

# If nothing found
notify-send "No browser found" "Install Brave, Firefox, Zen Browser, Vivaldi, or LibreWolf."
