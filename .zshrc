# --- History Settings ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt SHARE_HISTORY         # Share history between tabs immediately
setopt HIST_IGNORE_ALL_DUPS  # Do not save duplicate commands
setopt HIST_IGNORE_SPACE     # Don't save commands starting with a space

# --- Environment & Version Manager ---
eval "$(mise activate zsh)"

# Set default editor (Dynamic check)
if (( $+commands[micro] )); then
    export EDITOR='micro'   # Default terminal editor
    export VISUAL='micro'   # Visual editor (for git/cron)
else
    export EDITOR='nano'    # Fallback editor
    export VISUAL='nano'    # Fallback visual editor
fi

# --- Zinit Installer & Loader ---
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load Zinit extensions
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# --- FZF & Navigation ---
# Use system FZF if available, but load keybindings/completions via Zinit
if (( $+commands[fzf] )); then
    # Load shell integration scripts (Ctrl+R, Ctrl+T)
    zinit ice wait lucid multisrc"shell/{key-bindings,completion}.zsh"
    zinit light junegunn/fzf

    # Better Tab completion with preview (depends on fzf)
    zinit light Aloxaf/fzf-tab

    # Style fzf-tab to match system colors
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
fi

# --- History Search & Keybindings ---
zinit light zsh-users/zsh-history-substring-search

# Standard History Search
bindkey '^[[A' history-substring-search-up    # [Arrow Up] History Search
bindkey '^[[B' history-substring-search-down  # [Arrow Down] History Search

# Modern Navigation
bindkey '^[[1;5C' forward-word      # [Ctrl+Right] Jump forward one word
bindkey '^[[1;5D' backward-word     # [Ctrl+Left] Jump backward one word

# Word Deletion
bindkey '^H' backward-kill-word     # [Ctrl+Backspace] Delete word backward
bindkey '^[[3;5~' kill-word         # [Ctrl+Delete] Delete word forward

# Undo/Redo
bindkey '^z' undo                   # [Ctrl+Z] Undo last action

# --- Autosuggestions & Completions ---
zinit wait lucid for atload"_zsh_autosuggest_start" zsh-users/zsh-autosuggestions
zinit wait lucid for zsh-users/zsh-completions

# --- Modern Tools & Aliases (Safe Mode) ---

# Dynamic alias for Editor (uses $EDITOR variable)
alias e='$EDITOR'                             # Quick edit (uses default EDITOR)

if (( $+commands[eza] )); then
    alias ls='eza --icons --git --group-directories-first --time-style=long-iso' # List files (icons+git)
    alias ll='eza -l --icons --git --group-directories-first --time-style=long-iso' # List details
    alias la='eza -la --icons --git --group-directories-first --time-style=long-iso' # List all+hidden
    alias lt='eza --tree --level=2 --icons' # Show file tree (depth 2)
fi

if (( $+commands[bat] )); then
    alias cat='bat --style=plain'             # Print text (clean output)
    alias catp='bat --style=numbers,changes'  # Print code (numbered lines)
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh --cmd cd)"
fi

if (( $+commands[rg] )); then
    alias r='rg --smart-case --hidden'        # Fast search (grep alternative)
fi

if (( $+commands[fd] )); then
    alias f='fd --hidden --exclude .git'      # Find files (find alternative)
fi

# --- Custom Functions ---

mkcd() { # Create directory and cd into it
    mkdir -p "$1" && cd "$1"
}

# --- System Inspector (Smart dotinfo) ---
dotinfo() { # Show summary of plugins, aliases, and keybindings
    print -P "\n%F{033}=== 🧩 ZINIT PLUGINS (Load Times) ===%f"
    zinit times

    print -P "\n%F{033}=== 🔧 ENVIRONMENT VARIABLES ===%f"
    # Format: Variable (Magenta) = Value (Cyan) # Comment (Grey)
    grep -E "^\s*export" ~/.zshrc | while read line; do
        # Extract Name (remove 'export', take before '=')
        name=$(echo "$line" | sed -E "s/^\s*export ([^=]+)=.*/\1/")
        # Extract Value (between '=' and '#')
        val=$(echo "$line" | sed -E "s/^[^=]+=//; s/#.*//")
        # Extract Comment
        comment=$(echo "$line" | sed -E "s/.*# //")
        [[ "$comment" == "$line" ]] && comment="" || comment="# $comment"

        # Fixed width: Name(12), Value(45)
        printf " %b%-12s%b %b=%b %b%-45s%b %b%s%b\n" \
            "\e[35m" "$name" "\e[0m" \
            "\e[37m" "\e[0m" \
            "\e[36m" "$val" "\e[0m" \
            "\e[90m" "$comment" "\e[0m"
    done

    print -P "\n%F{033}=== 🛠  ALIASES & TOOLS ===%f"
    grep -E "^\s*alias" ~/.zshrc | while read line; do
        name=$(echo "$line" | sed -E "s/^\s*alias ([^=]+)=.*/\1/")
        cmd=$(echo "$line" | sed -E "s/^[^=]+=//; s/#.*//")
        comment=$(echo "$line" | sed -E "s/.*# //")
        [[ "$comment" == "$line" ]] && comment="" || comment="# $comment"

        printf " %b%-12s%b %b=%b %b%-45s%b %b%s%b\n" \
            "\e[32m" "$name" "\e[0m" \
            "\e[37m" "\e[0m" \
            "\e[36m" "$cmd" "\e[0m" \
            "\e[90m" "$comment" "\e[0m"
    done

    print -P "\n%F{033}=== 🎹 KEYBINDINGS ===%f"
    grep -E "^\s*bindkey" ~/.zshrc | grep "#" | while read line; do
        key=$(echo "$line" | awk '{print $2}' | tr -d "'")
        cmd=$(echo "$line" | awk '{print $3}')
        comment=$(echo "$line" | sed -E "s/.*# //")

        printf " %b%-12s%b %b->%b %b%-45s%b %b# %s%b\n" \
            "\e[33m" "$key" "\e[0m" \
            "\e[37m" "\e[0m" \
            "\e[36m" "$cmd" "\e[0m" \
            "\e[90m" "$comment" "\e[0m"
    done

    print -P "\n%F{033}=== 🚀 FUNCTIONS ===%f"
    grep -E "^[a-zA-Z0-9_]+\(\)\s*\{" ~/.zshrc | while read line; do
        name=$(echo "$line" | sed -E "s/^([a-zA-Z0-9_]+)\(\).*/\1/")
        comment=$(echo "$line" | sed -E "s/.*# //")
        [[ "$comment" == "$line" ]] && comment="" || comment="# $comment"

        printf " %b%-12s%b %b:%b %b%s%b\n" \
            "\e[35m" "$name" "\e[0m" \
            "\e[37m" "\e[0m" \
            "\e[90m" "$comment" "\e[0m"
    done

    print -P "\n%F{240}(Edit ~/.zshrc to update this list)%f"
}

# --- Syntax Highlighting (Must be last) ---
zinit wait lucid for \
    atinit"ZINIT[COMPINIT_OPTS]='-C'; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting

eval "$(starship init zsh)"
