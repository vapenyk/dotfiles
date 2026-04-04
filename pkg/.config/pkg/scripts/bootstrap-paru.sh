#!/usr/bin/env bash
# ~/.config/pkg/scripts/bootstrap-paru.sh
# Called automatically when paru is not in official repos.
# Builds paru from AUR using only base-devel (always available on Arch).
set -euo pipefail

echo "[pkg bootstrap] Building paru from AUR..."

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

git clone --depth=1 https://aur.archlinux.org/paru.git "$tmpdir"
cd "$tmpdir"
makepkg -si --noconfirm

echo "[pkg bootstrap] paru installed successfully"
