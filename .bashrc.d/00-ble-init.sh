# =============================================================================
# 00-ble-init.sh — ble.sh early initialisation
# =============================================================================
# Loaded by: ~/.bashrc.d/ — MUST be first (prefix 00)
# Paired with: 99-ble-attach.sh which activates ble.sh after all other files
# Docs: https://github.com/akinomyoga/ble.sh
#
# Searches for ble.sh in standard install locations.
# Loads it with --attach=none so it does not activate yet — this allows all
# other bashrc.d files to run first (aliases, functions, tools, etc.).
# Only runs in interactive shells ([[ $- == *i* ]]).
# Warns via _gum_log_warn if ble.sh is not found (requires 05-colors.sh).
# =============================================================================

_ble_path=''
for _p in \
    "$HOME/.local/share/blesh/ble.sh" \
    "/usr/share/blesh/ble.sh" \
    "/usr/local/share/blesh/ble.sh"
do
    [[ -f "$_p" ]] && { _ble_path="$_p"; break; }
done

if [[ $- == *i* && -n "$_ble_path" ]]; then
    source -- "$_ble_path" --attach=none
fi

unset _ble_path _p