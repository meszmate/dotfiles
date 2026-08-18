-- Window, layer and workspace rules.
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/


-- Window rules ---------------------------------------------------------------

-- Slight translucency for terminals and the file manager (blur is on).
hl.window_rule({ name = "terminal-opacity", match = { class = "^(kitty|kitty-scratch|kitty-agent)$" }, opacity = "0.95 0.88" })
hl.window_rule({ name = "thunar-opacity",   match = { class = "^(thunar|Thunar)$" }, opacity = "0.96 0.92" })

-- Utility windows open floating and centred instead of tiling.
hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|blueman-manager|nm-connection-editor|qt6ct|qt5ct|nwg-look|xdg-desktop-portal-gtk|file-roller|org\\.gnome\\.FileRoller|imv|swappy|hyprsysteminfo|org\\.gnome\\.Loupe)$" },
    float = true, center = true, size = { "monitor_w*0.6", "monitor_h*0.65" },
})
hl.window_rule({ name = "float-dialogs", match = { title = "^(Open File|Open Folder|Save As|Save File|Select Folder|File Upload|Choose Files|Preferences|Library|Picture in picture)$" }, float = true, center = true })

-- Polkit prompt / graceful shutdown dialog: float, dim the rest, keep focus.
hl.window_rule({ name = "modal-prompts", match = { class = "^(hyprpolkitagent|org\\.hyprland\\.hyprpolkitagent|hyprshutdown|org\\.hyprland\\.hyprshutdown)$" }, float = true, center = true, dim_around = true, stay_focused = true, pin = true })
hl.window_rule({ name = "portal-picker",  match = { class = "^(xdg-desktop-portal-hyprland)$" }, float = true, center = true, dim_around = true })

-- Browser picture-in-picture: float, pin, put in the corner.
hl.window_rule({ name = "pip", match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true, size = { "monitor_w*0.28", "monitor_h*0.28" }, move = { "monitor_w-window_w-24", "monitor_h-window_h-24" }, no_focus = true })

-- Don't let apps steal fullscreen/maximize state; fixes XWayland drag glitches.
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ name = "fix-xwayland-drags", match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, no_focus = true })

-- Keep the screen awake while something is fullscreen (video, presentations).
hl.window_rule({ name = "idle-inhibit-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- Layer rules (bars, menus, notifications) -----------------------------------
hl.layer_rule({ match = { namespace = "^(waybar)$" },                       blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "^(rofi)$" },                         blur = true, ignore_alpha = 0.3, animation = "popin 90%" })
hl.layer_rule({ match = { namespace = "^(keybinds)$" },                     blur = true, ignore_alpha = 0.3, animation = "popin 92%" })   -- bin/keybinds
hl.layer_rule({ match = { namespace = "^(swaync-control-center)$" },        blur = true, ignore_alpha = 0.3, animation = "slide" })
hl.layer_rule({ match = { namespace = "^(swaync-notification-window)$" },   blur = true, ignore_alpha = 0.3, animation = "slide" })
hl.layer_rule({ match = { namespace = "^(swayosd)$" },                      blur = true, ignore_alpha = 0.3, animation = "fade" })
hl.layer_rule({ match = { namespace = "^(selection)$" },                    no_anim = true })   -- slurp
hl.layer_rule({ match = { namespace = "^(hyprpicker)$" },                   no_anim = true })
hl.layer_rule({ match = { namespace = "^(logout_dialog)$" },                blur = true, ignore_alpha = 0.3 })

-- Workspace rules ------------------------------------------------------------

-- Scratchpads: toggling an empty one spawns a terminal in a persistent tmux
-- session, so the shell/agents survive closing the window.
hl.workspace_rule({ workspace = "special:scratch", on_created_empty = "kitty --class kitty-scratch tmux new-session -A -s scratch", gaps_out = 30 })
hl.workspace_rule({ workspace = "special:agent",   on_created_empty = "kitty --class kitty-agent tmux new-session -A -s agent",     gaps_out = 30 })

-- Smart gaps: a lone tiled window on a workspace gets no gaps/border/rounding.
-- Uncomment to enable.
-- hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]s[false]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" },   border_size = 0, rounding = 0 })
