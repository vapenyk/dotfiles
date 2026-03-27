# =============================================================================
# install-bashrc-d.sh — Installer for modular ~/.bashrc.d/ setup
# =============================================================================
# Usage: sh install-bashrc-d.sh
# Depends on: sh, grep, cat, printf
# POSIX sh compatible.
#
# Functions:
#   _install_loader TARGET_FILE — injects the ~/.bashrc.d loader block
#   _install_for_bash           — installs into ~/.bashrc
#   _install_for_zsh            — installs into ~/.zshrc
# =============================================================================

# -----------------------------------------------------------------------------
# _install_loader TARGET_FILE
# Safely appends the ~/.bashrc.d loader block to the target rc file.
# Skips if the block is already present.
# -----------------------------------------------------------------------------
_install_loader() {
    _target="$1"

    _block=$(cat << 'EOF'

# Load custom scripts from ~/.bashrc.d
if [ -d "$HOME/.bashrc.d" ]; then
    for _rc in "$HOME"/.bashrc.d/*; do
        [ -f "$_rc" ] && . "$_rc"
    done
    unset _rc
fi
EOF
)

    if grep -q '\.bashrc\.d' "$_target" 2>/dev/null; then
        printf 'Skipping: ~/.bashrc.d loader already present in %s\n' "$_target"
    else
        printf 'Installing: Appending loader to %s\n' "$_target"
        printf '%s\n' "$_block" >> "$_target"
        printf 'Done. Run: source %s\n' "$_target"
    fi

    unset _target _block
}

# -----------------------------------------------------------------------------
# _install_for_bash — install loader into ~/.bashrc
# -----------------------------------------------------------------------------
_install_for_bash() {
    _bashrc="$HOME/.bashrc"
    if [ ! -f "$_bashrc" ]; then
        printf 'Creating %s\n' "$_bashrc"
        printf '# ~/.bashrc\n' > "$_bashrc"
    fi
    _install_loader "$_bashrc"
    unset _bashrc
}

# -----------------------------------------------------------------------------
# _install_for_zsh — install loader into ~/.zshrc
# -----------------------------------------------------------------------------
_install_for_zsh() {
    _zshrc="$HOME/.zshrc"
    if [ ! -f "$_zshrc" ]; then
        printf 'Creating %s\n' "$_zshrc"
        printf '# ~/.zshrc\n' > "$_zshrc"
    fi
    _install_loader "$_zshrc"
    unset _zshrc
}

# --- main --------------------------------------------------------------------

printf '\n=== ~/.bashrc.d installer ===\n\n'

_install_for_bash

if command -v zsh >/dev/null 2>&1; then
    _install_for_zsh
else
    printf 'Skipping zsh: zsh not found in PATH\n'
fi

printf '\nRestart your shell or source the rc file to apply changes.\n\n'

unset -f _install_loader _install_for_bash _install_for_zsh
