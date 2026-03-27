# =============================================================================
# ~/.bashrc.d/99-custom.sh
# =============================================================================
# Loaded by bash for every interactive non-login shell.
# For login shells, source this from ~/.bash_profile:
#   [[ -f ~/.bashrc ]] && source ~/.bashrc
# =============================================================================

# Not interactive — bail out early (scp, rsync, etc.)
[[ $- == *i* ]] || return

# =============================================================================
# PATH
# =============================================================================

_path_prepend() {
    [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"
}

_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.cargo/bin"
_path_prepend "$HOME/go/bin"

export PATH
unset -f _path_prepend

# =============================================================================
# BREW
# =============================================================================
# HOMEBREW_PREFIX is exported by brew shellenv — skip if already initialized
# (e.g. via /etc/profile.d/brew.sh on Aurora/uBlue).

if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
    for _p in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [[ -x "$_p" ]] && eval "$("$_p" shellenv)" && break
    done
    unset _p
fi

# =============================================================================
# MISE
# =============================================================================
# Note: no guard on MISE_SHELL — activate must run every shell to register
# _mise_hook into PROMPT_COMMAND so PATH updates when changing directories.

if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi

# =============================================================================
# HISTORY
# =============================================================================

HISTFILE="$HOME/.bash_history"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth   # ignore duplicates + lines starting with space

shopt -s histappend      # append to HISTFILE instead of overwriting
shopt -s checkwinsize    # update LINES/COLUMNS after each command
shopt -s globstar        # enable ** recursive glob (e.g. cat **/*.json)
shopt -s cdspell         # auto-correct minor typos in cd arguments

# =============================================================================
# KEY BINDINGS
# =============================================================================

bind '"\\e[1;5C": forward-word'       # Ctrl+Right     — jump word forward
bind '"\\e[1;5D": backward-word'      # Ctrl+Left      — jump word backward
bind '"\\C-h":    backward-kill-word' # Ctrl+Backspace — delete word back
bind '"\\e[3;5~": kill-word'          # Ctrl+Delete    — delete word forward

# =============================================================================
# ALIASES
# =============================================================================

alias yay='paru'
alias zj="zellij"
alias ll='ls -lh'
alias la='ls -lAh'
alias lt='ls -lRh'
alias l='ls -CF'

# =============================================================================
# FUNCTIONS
# =============================================================================

mkcd() { mkdir -p "$1" && cd "$1"; }  # create directory and cd into it

# =============================================================================
# SSH
# =============================================================================

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/rbw/ssh-agent-socket"

# =============================================================================
# FZF
# =============================================================================
# Ctrl+T (file picker), Alt+C (cd), Ctrl+R (history search).

if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
fi

# =============================================================================
# STARSHIP
# =============================================================================
# STARSHIP_SHELL is exported by starship on init — skip if already initialized
# (e.g. via /etc/profile.d/90-aurora-starship.sh on Aurora/uBlue).

if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
