#!/usr/bin/env bash
# ~/.config/pkg/scripts/after-sync.sh
# Runs after EVERY `pkg sync`. Edit freely — runs each time, not just once.
#
# Available env vars:
#   PKG_EVENT       = "after-sync"
#   PKG_CONFIG_DIR  = path to ~/.config/pkg
#   PKG_DATA_DIR    = path to ~/.local/share/pkg
set -euo pipefail

echo "[pkg hook] after-sync — $(date '+%Y-%m-%d %H:%M')"

# Uncomment to apply dotfiles via stow after all packages are in place:
# cd ~/dotfiles && stow --restow --ignore='.git' .

# Uncomment for a desktop notification when sync finishes:
# notify-send "pkg sync" "All packages installed" --icon=package-x-generic
