#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# install-git-config.sh — Git configuration and SSH signing setup
# =============================================================================
# Usage: ./install-git-config.sh
# Depends on: git, rbw, mkdir, echo
#
# Functions defined here:
#   setup-git-config() — applies global Git settings and SSH signing
# =============================================================================


# =============================================================================
# CONFIGURATION — edit strings here without touching the logic below
# =============================================================================

# --- Git defaults -------------------------------------------------------------
readonly CFG_DEFAULT_BRANCH="main"
readonly CFG_DEFAULT_EDITOR="${EDITOR:-micro}"
readonly CFG_ALLOWED_SIGNERS_FILE="$HOME/.ssh/allowed_signers"
readonly CFG_SSH_KEY_SUFFIX="signingkey"

# --- Prompts ------------------------------------------------------------------
readonly MSG_PROMPT_NAME="Enter your Git username"
readonly MSG_PROMPT_EMAIL="Enter your Git email"
readonly MSG_PROMPT_CONFIRM="Apply these settings? [y/N]: "

# --- Info / success -----------------------------------------------------------
readonly MSG_START="Configuring global Git settings in ~/.gitconfig..."
readonly MSG_SIGNING="Configuring SSH commit signing..."
readonly MSG_SIGNERS="Setting up $CFG_ALLOWED_SIGNERS_FILE..."
readonly MSG_SUCCESS="Global Git configuration and SSH signing setup applied."

# --- Warnings / errors --------------------------------------------------------
readonly MSG_WARN_NO_KEY="Warning: No SSH key found in Bitwarden with name '$CFG_SSH_KEY_SUFFIX'."
readonly MSG_WARN_INCOMPLETE="         SSH signing configuration might be incomplete."
readonly MSG_ERR_NAME_EMPTY="Error: Username cannot be empty."
readonly MSG_ERR_EMAIL_INVALID="Error: Email format is invalid (expected user@domain.tld)."
readonly MSG_ERR_GIT_CONFIG="Error: Failed to apply git config."
readonly MSG_CANCELLED="Cancelled. No changes were made."


# =============================================================================
# HELPERS
# =============================================================================

log() {
    echo "[$(date +%H:%M:%S)] $*"
}

# Prompt with optional default value shown in brackets.
# Usage: prompt_with_default <var_name> <message> [default]
prompt_with_default() {
    local -n _ref=$1
    local message=$2
    local default=${3:-}
    local hint=""

    [[ -n "$default" ]] && hint=" [$default]"
    read -rp "${message}${hint}: " _ref
    _ref="${_ref:-$default}"
}

# Validate non-empty string.
validate_not_empty() {
    local value=$1
    local err_msg=$2
    if [[ -z "$value" ]]; then
        echo "$err_msg"
        return 1
    fi
}

# Validate email format.
validate_email() {
    local value=$1
    if [[ ! "$value" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        echo "$MSG_ERR_EMAIL_INVALID"
        return 1
    fi
}


# =============================================================================
# MAIN
# =============================================================================

# -----------------------------------------------------------------------------
# setup-git-config — configures user info, editor, init, and SSH commit signing
# Reads CFG_DEFAULT_EDITOR and expects an SSH key in the ssh-agent.
# All settings are applied globally to ~/.gitconfig.
# -----------------------------------------------------------------------------
setup-git-config() {
    log "$MSG_START"
    echo ""

    # --- Collect current values as defaults -----------------------------------
    local current_name current_email
    current_name=$(git config --global user.name  2>/dev/null || true)
    current_email=$(git config --global user.email 2>/dev/null || true)

    # --- Interactive input with validation ------------------------------------
    local git_username=""
    while true; do
        prompt_with_default git_username "$MSG_PROMPT_NAME" "$current_name"
        validate_not_empty "$git_username" "$MSG_ERR_NAME_EMPTY" && break
    done

    local git_email=""
    while true; do
        prompt_with_default git_email "$MSG_PROMPT_EMAIL" "$current_email"
        validate_email "$git_email" && break
    done

    # --- Confirmation ---------------------------------------------------------
    echo ""
    echo "  name  : $git_username"
    echo "  email : $git_email"
    echo "  editor: $CFG_DEFAULT_EDITOR"
    echo "  branch: $CFG_DEFAULT_BRANCH"
    echo ""
    read -rp "$MSG_PROMPT_CONFIRM" confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo "$MSG_CANCELLED"
        return 0
    fi
    echo ""

    # --- Apply base config ----------------------------------------------------
    git config --global user.name  "$git_username"  || { log "$MSG_ERR_GIT_CONFIG"; return 1; }
    git config --global user.email "$git_email"     || { log "$MSG_ERR_GIT_CONFIG"; return 1; }
    git config --global core.editor        "$CFG_DEFAULT_EDITOR"  || { log "$MSG_ERR_GIT_CONFIG"; return 1; }
    git config --global init.defaultBranch "$CFG_DEFAULT_BRANCH"  || { log "$MSG_ERR_GIT_CONFIG"; return 1; }

    # --- SSH signing ----------------------------------------------------------
    local signing_key
    signing_key=$(rbw get "$CFG_SSH_KEY_SUFFIX" 2>/dev/null || true)

    if [[ -z "$signing_key" ]]; then
        log "$MSG_WARN_NO_KEY"
        log "$MSG_WARN_INCOMPLETE"
    fi

    log "$MSG_SIGNING"
    git config --global user.signingkey          "key::${signing_key}" || { log "$MSG_ERR_GIT_CONFIG"; return 1; }
    git config --global gpg.format               "ssh"                 || { log "$MSG_ERR_GIT_CONFIG"; return 1; }
    git config --global commit.gpgsign           "true"                || { log "$MSG_ERR_GIT_CONFIG"; return 1; }

    # --- Allowed signers ------------------------------------------------------
    log "$MSG_SIGNERS"
    mkdir -p "$HOME/.ssh"
    echo "${git_email} ${signing_key}" > "$CFG_ALLOWED_SIGNERS_FILE"
    git config --global gpg.ssh.allowedSignersFile "$CFG_ALLOWED_SIGNERS_FILE" || { log "$MSG_ERR_GIT_CONFIG"; return 1; }

    log "$MSG_SUCCESS"
}

# Execute the installation function
setup-git-config
