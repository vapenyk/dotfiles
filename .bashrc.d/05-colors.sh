# =============================================================================
# 05-colors.sh — Terminal color variables and output helpers
# =============================================================================
# Loaded by: ~/.bashrc.d/ (alphabetical order, before all other files)
# Used by:   40-functions.sh, 10-env.sh, 00-ble-init.sh, 95-motd.sh
#
# Philosophy:
#   - Bold is the PRIMARY readability mechanism — always visible in any theme
#   - Colors are SECONDARY accents — semantic meaning (ok/warn/err)
#   - Bold + color = guaranteed visible even if the color slot is dark
#   - Dim = tput dim attribute, not a color slot — always readable
#   - No hardcoded 256-color codes — only base slots 0-15 which all themes remap
#
# Color variables:
#   C_RESET   — reset all attributes
#   C_BOLD    — bold, for names and labels (primary visibility)
#   C_DIM     — dim attribute, for secondary/contextual text
#   C_ACCENT  — blue (slot 4), for section headers, always paired with C_BOLD
#   C_OK      — green (slot 2), always paired with C_BOLD
#   C_WARN    — yellow (slot 3), always paired with C_BOLD
#   C_ERR     — red (slot 1), always paired with C_BOLD
#
# gum helpers (https://github.com/charmbracelet/gum):
#   gum is optional — all helpers fall back to plain output if not installed.
#   _gum_available()  — check if gum is installed
#   _gum_log_info()   — info message
#   _gum_log_warn()   — warning message
#   _gum_log_error()  — error message
#   _gum_header()     — section header with border
#   _gum_table()      — render CSV from stdin as table
# =============================================================================

if [[ $(tput colors 2>/dev/null) -ge 8 ]]; then
    C_RESET=$(tput sgr0)
    C_BOLD=$(tput bold)
    C_DIM=$(tput dim)
    C_ACCENT=$(tput setaf 4)    # blue — headers only, always paired with C_BOLD
    C_OK=$(tput setaf 2)        # green — success, always paired with C_BOLD
    C_WARN=$(tput setaf 3)      # yellow — warning, always paired with C_BOLD
    C_ERR=$(tput setaf 1)       # red — error, always paired with C_BOLD
else
    C_RESET='' C_BOLD='' C_DIM=''
    C_ACCENT='' C_OK='' C_WARN='' C_ERR=''
fi

export C_RESET C_BOLD C_DIM C_ACCENT C_OK C_WARN C_ERR

# --- gum helpers ------------------------------------------------------------

_gum_available() { command -v gum >/dev/null 2>&1; }

_gum_log_info() {
    if _gum_available; then gum log --level info  "$1"
    else echo "  ✦ dotfiles: $1"; fi
}

_gum_log_warn() {
    if _gum_available; then gum log --level warn  "$1"
    else echo "  ✦ dotfiles: $1"; fi
}

_gum_log_error() {
    if _gum_available; then gum log --level error "$1"
    else echo "  ✦ dotfiles: $1"; fi
}

_gum_header() {
    if _gum_available; then
        gum style --bold --border normal --padding "0 1" "$1"
    else
        echo -e "\n${C_BOLD}${C_ACCENT}=== $1 ===${C_RESET}"
    fi
}

# reads CSV with header from stdin, renders as table or falls back to column
_gum_table() {
    if _gum_available; then gum table --print --separator "|"
    else column -t -s ','; fi
}

export -f _gum_available _gum_log_info _gum_log_warn _gum_log_error _gum_header _gum_table