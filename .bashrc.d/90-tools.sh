# =============================================================================
# 90-tools.sh — Tool integrations and shell prompt
# =============================================================================
# Loaded by: ~/.bashrc.d/ (alphabetical order, before 99-ble-attach.sh)
#
# Tools:
#   fzf     — fuzzy finder; when ble.sh is active uses blesh-contrib integration
#             to avoid key binding conflicts (Ctrl+R, Ctrl+T, Alt+C).
#             Without ble.sh falls back to standard "fzf --bash" init.
#             blesh-contrib is bundled with "make install" at:
#             ~/.local/share/blesh/contrib/
#
#   zoxide  — smarter cd with frecency; replaces cd via --cmd cd
#
#   starship — cross-shell prompt; initialised last so it wraps the final PS1
# =============================================================================

if command -v fzf >/dev/null 2>&1; then
    export FZF_COMPLETION_DIR_COMMANDS="cd pushd rmdir"

    if [[ ${BLE_VERSION-} ]]; then
        ble-import -d integration/fzf-completion
        ble-import -d integration/fzf-key-bindings
    else
        eval "$(fzf --bash)"
    fi
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash --cmd cd)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi