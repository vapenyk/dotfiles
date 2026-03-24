local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Set WSL as the default domain
-- config.default_domain = "WSL:Ubuntu"

-- Font settings
config.font = wezterm.font("Maple Mono NF")
config.font_size = 14.0

-- Color scheme
config.color_scheme = "Ayu Dark (Gogh)"

-- Appearance
config.window_background_opacity = 1.0
config.window_decorations = "RESIZE"
config.initial_cols = 220
config.initial_rows = 50

-- Tabs
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false

-- General preferences
config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"

-- Cursor
config.default_cursor_style = "BlinkingBar"

-- Padding
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 0,
}

-- Keybindings
local act = wezterm.action

config.keys = {
  -- Alt+1-9 to switch tabs by index
  { key = "1", mods = "ALT", action = act.ActivateTab(0) },
  { key = "2", mods = "ALT", action = act.ActivateTab(1) },
  { key = "3", mods = "ALT", action = act.ActivateTab(2) },
  { key = "4", mods = "ALT", action = act.ActivateTab(3) },
  { key = "5", mods = "ALT", action = act.ActivateTab(4) },
  { key = "6", mods = "ALT", action = act.ActivateTab(5) },
  { key = "7", mods = "ALT", action = act.ActivateTab(6) },
  { key = "8", mods = "ALT", action = act.ActivateTab(7) },
  { key = "9", mods = "ALT", action = act.ActivateTab(8) },
}

return config
