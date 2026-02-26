# =============================================================================
# 30-aliases.sh — Aliases for modern CLI tools
# =============================================================================
# Loaded by: ~/.bashrc.d/ (alphabetical order)
# Note: 'e' for opening $EDITOR is a function defined in 40-functions.sh
#
# All aliases are conditional — only set if the tool is installed.
# This makes the config portable across machines where some tools may be absent.
#
# Tools:
#   eza   — modern ls replacement with icons and git status
#   bat   — modern cat with syntax highlighting
#   rg    — ripgrep, fast recursive search
#   fd    — fast find replacement
# =============================================================================

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --git --group-directories-first --time-style=long-iso --hyperlink'
    alias ll='eza -l --icons --git --group-directories-first --time-style=long-iso --hyperlink'
    alias la='eza -la --icons --git --group-directories-first --time-style=long-iso --hyperlink'
    alias lt='eza --tree --level=2 --icons --hyperlink'
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=plain'
    alias catp='bat --style=numbers,changes'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if command -v rg >/dev/null 2>&1; then
    alias r='rg --smart-case --hidden'
fi

if command -v fd >/dev/null 2>&1; then
    alias f='fd --hidden --exclude .git'
fi