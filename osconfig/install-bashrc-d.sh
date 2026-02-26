# =============================================================================
# install-bashrc-d.sh — Installer for modular ~/.bashrc.d/ setup
# =============================================================================
# Usage: ./install-bashrc-d.sh
# Depends on: bash, grep, cat
#
# Functions defined here:
#   setup-bashrc-d() — injects the ~/.bashrc.d loader into ~/.bashrc
# =============================================================================

# -----------------------------------------------------------------------------
# setup-bashrc-d — safely appends the directory loading block to ~/.bashrc
# Checks for the existence of the string "~/.bashrc.d" in the target file.
# -----------------------------------------------------------------------------
setup-bashrc-d() { # Add ~/.bashrc.d/ loader to ~/.bashrc
    local bashrc="$HOME/.bashrc"

    local block_to_add
    block_to_add=$(cat << 'EOF'

# Load custom scripts from ~/.bashrc.d
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
EOF
    )

    if grep -q "\.bashrc\.d" "$bashrc" 2>/dev/null; then
        echo "Skipping: ~/.bashrc.d loader is already present in $bashrc"
    else
        echo "Installing: Appending ~/.bashrc.d loader to $bashrc..."
        echo "$block_to_add" >> "$bashrc"
        echo "Success: Run 'source ~/.bashrc' or restart your terminal to apply changes."
    fi
}

# Execute the installation function
setup-bashrc-d
