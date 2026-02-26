# =============================================================================
# 99-ble-attach.sh — ble.sh final activation
# =============================================================================
# Loaded by: ~/.bashrc.d/ — MUST be last (prefix 99)
# Paired with: 00-ble-init.sh which loaded ble.sh with --attach=none
#
# Activates ble.sh after all other bashrc.d files have been sourced.
# This ensures aliases, functions, and tool integrations are all in place
# before ble.sh takes over input handling.
# No-op if ble.sh was not loaded (BLE_VERSION is unset).
# =============================================================================

[[ ! ${BLE_VERSION-} ]] || ble-attach