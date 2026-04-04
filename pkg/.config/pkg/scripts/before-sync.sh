#!/usr/bin/env bash
# ~/.config/pkg/scripts/before-sync.sh
# Runs before EVERY `pkg sync`. Edit freely — runs each time, not just once.
#
# Available env vars:
#   PKG_EVENT       = "before-sync"
#   PKG_CONFIG_DIR  = path to ~/.config/pkg
#   PKG_DATA_DIR    = path to ~/.local/share/pkg
set -euo pipefail

echo "[pkg hook] before-sync — $(date '+%Y-%m-%d %H:%M')"

# Uncomment to pull dotfiles before installing new packages:
# cd ~/dotfiles && git pull --ff-only

# Uncomment to check for pending system updates first:
# checkupdates || true
