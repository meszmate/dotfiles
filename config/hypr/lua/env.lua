-- Environment variables. These are exported before the display server starts,
-- so a full Hyprland restart is needed for changes here to apply.
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Cursor
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- XDG session
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Toolkits: prefer native Wayland everywhere
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")           -- Qt apps take colours/fonts from config/qt6ct
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")     -- Electron apps (t3code, discord, ...) on Wayland
hl.env("CLUTTER_BACKEND", "wayland")

-- Editor for anything that asks
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")

-- User tool directories on PATH for everything launched from Hyprland (rofi,
-- keybinds, tray apps): claude/t3code in ~/.local/bin, cargo, go, bun, pnpm.
-- Idempotent: hl.env runs again on every config reload.
local home = os.getenv("HOME")
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
local extra = { home .. "/.local/bin", home .. "/.cargo/bin", home .. "/go/bin", home .. "/.bun/bin", home .. "/.local/share/pnpm/bin", home .. "/.local/share/pnpm" }
for i = #extra, 1, -1 do
    local dir = extra[i]
    if not (":" .. path .. ":"):find(":" .. dir .. ":", 1, true) then
        path = dir .. ":" .. path
    end
end
hl.env("PATH", path)
