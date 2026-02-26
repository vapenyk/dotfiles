# =============================================================================
# 10-env.sh — Environment variables, PATH setup, version managers
# =============================================================================
# Loaded by: ~/.bashrc.d/ (alphabetical order)
# Depends on: 05-colors.sh (_gum_log_info)
#
# Order matters:
#   1. PATH — must be set up first so all subsequent commands can be found
#   2. mise — activates version manager shims (needs PATH ready)
#   3. EDITOR / VISUAL — set after mise in case editor was installed via mise
#
# PATH setup:
#   _path_prepend() — safely prepends a directory, skips if already present
#                     or if the directory does not exist.
#                     Notifies via _gum_log_info when a new dir enters PATH —
#                     happens the first session after the directory is created.
#   Adds: ~/.local/bin, ~/bin, ~/.cargo/bin, ~/go/bin
#   Brew — soft-initialised if installed but not yet in PATH (Linux/macOS)
#
# EDITOR priority: micro > nano > unset (avoids broken defaults)
# =============================================================================

# --- PATH helpers -----------------------------------------------------------

_path_prepend() {
    if [[ -d "$1" && ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH"
        _gum_log_info "$1 is now in PATH"
    fi
}

# User bins
_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/bin"

# Language toolchains
_path_prepend "$HOME/.cargo/bin"  # Rust
_path_prepend "$HOME/go/bin"      # Go

# Brew — soft init if installed but not in PATH yet
if ! command -v brew >/dev/null 2>&1; then
    for _brew_path in \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew \
        /home/linuxbrew/.linuxbrew/bin/brew
    do
        if [[ -x "$_brew_path" ]]; then
            eval "$("$_brew_path" shellenv)"
            break
        fi
    done
fi

unset -f _path_prepend
unset _brew_path

# --- Version manager --------------------------------------------------------

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi

# --- Editor -----------------------------------------------------------------

if command -v micro >/dev/null 2>&1; then
    export EDITOR='micro'
    export VISUAL='micro'
elif command -v nano >/dev/null 2>&1; then
    export EDITOR='nano'
    export VISUAL='nano'
fi