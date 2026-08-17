-- Programs started once with the session.
-- https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    -- Wayland env for D-Bus/systemd user services (portals, screen sharing)
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")   -- graphical sudo prompts

    -- Desktop shell
    hl.exec_cmd("waybar")            -- top bar
    hl.exec_cmd("swaync")            -- notifications + control center (SUPER+SHIFT+N)
    hl.exec_cmd("swayosd-server")    -- volume / brightness / caps-lock OSD
    -- wallpaper: make sure the wallpaper.current symlink exists, then start
    hl.exec_cmd("cd ~/.config/hypr && [ -e wallpaper.current ] || ln -sfn wallpaper.jpg ~/.config/hypr/wallpaper.current; exec hyprpaper")
    hl.exec_cmd("hypridle")          -- idle -> dim -> lock -> screen off
    hl.exec_cmd("~/.config/hypr/scripts/lock-fx prepare")  -- pre-render hyprlock backgrounds
    hl.exec_cmd("hyprsunset")        -- night light schedule (hyprsunset.conf)

    -- Tray applets
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")

    -- Clipboard: history for SUPER+C, and keep the clipboard alive after the
    -- source app closes
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)
