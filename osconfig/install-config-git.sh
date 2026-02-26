# =============================================================================
# install-git-config.sh — Git configuration and SSH signing setup
# =============================================================================
# Usage: ./install-git-config.sh
# Depends on: git, ssh-add, grep, mkdir, echo
#
# Functions defined here:
#   setup-git-config() — applies global Git settings and SSH signing
# =============================================================================

# -----------------------------------------------------------------------------
# setup-git-config — configures user info, editor, init, and SSH commit signing
# Reads $EDITOR (defaults to micro) and expects an SSH key in the ssh-agent.
# All settings are applied globally to ~/.gitconfig.
# -----------------------------------------------------------------------------
setup-git-config() { # Configure git and SSH commit signing globally
    echo "Installing: Configuring global Git settings in ~/.gitconfig..."

    # 1. Base User Configuration
    git config --global user.name "Alexender Yatsenko"
    git config --global user.email "ayatsenkok@gmail.com"

    # 2. Core and Init Configuration
    git config --global core.editor "${EDITOR:-micro}"
    git config --global init.defaultBranch "main"

    # Retrieve the SSH key from ssh-agent
    local signing_key
    signing_key=$(ssh-add -L 2>/dev/null | grep 'signingkey$')

    if [[ -z "$signing_key" ]]; then
        echo "Warning: No SSH key found in ssh-agent ending with 'signingkey'."
        echo "         SSH signing configuration might be incomplete."
    fi

    # 3. SSH Signing Configuration
    echo "Installing: Configuring SSH commit signing..."
    git config --global user.signingkey "key::${signing_key}"
    git config --global gpg.format "ssh"
    git config --global commit.gpgsign "true"

    # 4. Allowed Signers Setup
    echo "Installing: Setting up ~/.ssh/allowed_signers..."

    # Ensure the .ssh directory exists
    mkdir -p "$HOME/.ssh"

    # Fetch the email we just set to use in the allowed_signers file
    local user_email
    user_email=$(git config --global user.email)

    # Write the email and key to the allowed_signers file
    echo "${user_email} ${signing_key}" > "$HOME/.ssh/allowed_signers"

    # Tell Git where to find the allowed_signers file for verification
    git config --global gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"

    echo "Success: Global Git configuration and SSH signing setup applied."
}

# Execute the installation function
setup-git-config
