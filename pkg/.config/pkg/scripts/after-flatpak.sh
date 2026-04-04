#!/usr/bin/env bash
# ~/.config/pkg/scripts/after-flatpak.sh
# Runs after every `pkg sync` for the flatpak backend.
# Masks openh264 — it's pulled in automatically by Flatpak but provides
# no value on a system that already has proper codec support.
set -euo pipefail

sudo flatpak mask org.freedesktop.Platform.openh264 2>/dev/null || true
