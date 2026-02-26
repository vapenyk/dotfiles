# =============================================================================
# 95-motd.sh — Startup banner (MOTD)
# =============================================================================
# Loaded by: ~/.bashrc.d/ (alphabetical order)
# Depends on: 40-functions.sh (dotinfo --short), 05-colors.sh (_gum_*)
# Paired with: toggle-motd() in 40-functions.sh to enable/disable
#
# Shows a minimal startup banner via 'dotinfo --short' on every new
# interactive shell session.
#
# Config file: ~/.config/dotfiles/motd.conf
#   "enabled"  — show banner (default if file does not exist)
#   "disabled" — skip banner
#
# To toggle: run 'toggle-motd'
# =============================================================================

_motd_conf="$HOME/.config/dotfiles/motd.conf"
_motd_state=$(cat "$_motd_conf" 2>/dev/null || echo "enabled")

[[ "$_motd_state" == "enabled" ]] && dotinfo --short

unset _motd_conf _motd_state