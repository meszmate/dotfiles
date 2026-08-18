-- Programs started once with the session.
-- https://wiki.hypr.land/Configuring/Basics/Autostart/

-- The desktop shell runs as systemd --user services (the units the packages
-- ship: Restart=on-failure, PartOf=graphical-session.target) instead of bare
-- execs, so a crash brings a component back within a second — waybar's mpris
-- module has segfaulted on player changes. Nothing activates
-- graphical-session.target when Hyprland is started without uwsm, so we do:
-- systemd/hyprland-session.target (linked into ~/.local/share/systemd/user on
-- every start, no installer step) binds to it.
--   logs:    journalctl --user -u waybar        restart: systemctl --user restart waybar
--   status:  systemctl --user status waybar swaync hypridle hyprpaper hyprsunset
local shell_units = "hyprpolkitagent waybar swaync hypridle hyprpaper hyprsunset"

hl.on("hyprland.start", function()
    hl.exec_cmd(table.concat({
        -- Wayland env for D-Bus/systemd user services (portals, screen sharing, our units)
        "dbus-update-activation-environment --systemd --all",
        "mkdir -p ~/.local/share/systemd/user",
        "ln -sfn ~/.config/hypr/systemd/hyprland-session.target ~/.local/share/systemd/user/hyprland-session.target",
        "systemctl --user daemon-reload",
        "systemctl --user reset-failed",
        -- wallpaper: make sure the wallpaper.current symlink exists before hyprpaper starts
        "[ -e ~/.config/hypr/wallpaper.current ] || ln -sfn wallpaper.jpg ~/.config/hypr/wallpaper.current",
        "systemctl --user start hyprland-session.target",
        -- restart, not start: after a compositor crash the units may still be up on the dead display
        "systemctl --user restart " .. shell_units,
        -- swayosd ships no unit → transient one with the same guarantees
        "systemctl --user stop swayosd-server 2>/dev/null",
        "systemd-run --user --unit=swayosd-server --collect -p Restart=on-failure -p RestartSec=1"
            .. " -p PartOf=graphical-session.target swayosd-server",
    }, "; "))
    hl.exec_cmd("~/.config/hypr/scripts/lock-fx prepare")  -- pre-render hyprlock backgrounds

    -- Tray applets
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")

    -- Clipboard: history for SUPER+C, and keep the clipboard alive after the
    -- source app closes
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)

hl.on("hyprland.shutdown", function()
    -- take the shell down with the session (best effort — systemd would also
    -- give up on units whose display is gone)
    hl.exec_cmd("systemctl --user stop hyprland-session.target swayosd-server")
end)
