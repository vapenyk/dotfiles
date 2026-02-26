# =============================================================================
# 20-history.sh — Bash history settings and readline key bindings
# =============================================================================
# Loaded by: ~/.bashrc.d/ (alphabetical order)
#
# History:
#   - Stores up to 50k entries in ~/.bash_history
#   - ignoreboth = ignore duplicates + lines starting with space
#   - histappend = append to history file, don't overwrite
#   - checkwinsize = update LINES/COLUMNS after each command
#
# Key bindings:
#   - Only applied when ble.sh is NOT active
#   - When ble.sh is active, equivalent bindings are in ~/.blerc via ble-bind
#   - ble.sh manages all input itself and ignores readline bind calls
# =============================================================================

HISTFILE="$HOME/.bash_history"
HISTSIZE=50000
HISTFILESIZE=50000
shopt -s histappend
HISTCONTROL=ignoreboth
shopt -s checkwinsize

if [[ ! ${BLE_VERSION-} ]]; then
    bind '"\e[A": history-search-backward' # [Arrow Up] History search by prefix
    bind '"\e[B": history-search-forward'  # [Arrow Down] History search by prefix
    bind '"\e[1;5C": forward-word'         # [Ctrl+Right] Jump forward one word
    bind '"\e[1;5D": backward-word'        # [Ctrl+Left] Jump backward one word
    bind '"\C-h": backward-kill-word'      # [Ctrl+Backspace] Delete word backward
    bind '"\e[3;5~": kill-word'            # [Ctrl+Delete] Delete word forward
fi