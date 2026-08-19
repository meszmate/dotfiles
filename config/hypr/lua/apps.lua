-- Programs used by keybinds and autostart. Change them here, not in binds.lua.
-- Other files: local apps = require("lua/apps")

local home    = os.getenv("HOME")
local scripts = home .. "/.config/hypr/scripts"
local rofi    = home .. "/.config/rofi/scripts"

return {
    terminal    = "kitty",
    browser     = "zen-browser",
    files       = "thunar",
    editor      = "kitty --title nvim nvim",
    t3code      = "t3code",

    -- rofi menus (config/rofi/scripts/*)
    launcher    = "rofi -show drun",
    run         = "rofi -show run",
    windows     = "rofi -show window",
    calc        = "rofi -show calc -modi calc -no-show-match -no-sort",
    emoji       = "rofi -show emoji -modi emoji",
    clipboard   = rofi .. "/clipboard",
    powermenu   = rofi .. "/powermenu",
    cheatsheet  = home .. "/.local/bin/keybinds",   -- GTK overlay (SUPER+/, waybar 󰌌; bin/keybinds)
    idle        = home .. "/.local/bin/idle",       -- idle modes (bin/idle; waybar 󰾪)
    wallpapers  = rofi .. "/wallpaper",

    -- helpers shipped in config/hypr/scripts/
    scripts     = scripts,
    screenshot  = scripts .. "/screenshot",
    record      = scripts .. "/record",
    colorpicker = scripts .. "/colorpicker",

    -- session
    lock        = "loginctl lock-session",   -- → hypridle → scripts/lock (falls back to the script directly)
    -- hyprshutdown closes apps gracefully before leaving the session
    logout      = "hyprshutdown",
    poweroff    = "hyprshutdown -t 'Shutting down…' --post-cmd 'systemctl poweroff'",
    reboot      = "hyprshutdown -t 'Restarting…' --post-cmd 'systemctl reboot'",
}
