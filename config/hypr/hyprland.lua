-- Hyprland configuration — Lua (Hyprland ≥ 0.55; the old hyprland.conf format
-- is deprecated). Docs: https://wiki.hypr.land/Configuring/Start/
--
-- The config is split into modules under lua/. Each require() runs in its own
-- scope, so a mistake in one file leaves the others working. Editing any of
-- them reloads Hyprland live (or run `hyprctl reload`).
--
--   lua/theme.lua      Catppuccin Mocha palette
--   lua/apps.lua       terminal / browser / menus used by binds
--   lua/env.lua        environment variables (need a restart)
--   lua/look.lua       gaps, borders, blur, shadows, animations, layouts
--   lua/input.lua      keyboard, touchpad, gestures
--   lua/rules.lua      window / layer / workspace rules
--   lua/binds.lua      keybinds (SUPER+/ shows a cheatsheet)
--   lua/autostart.lua  programs started with the session
--   lua/lockfx.lua     keypress hook for the lock screen's alarm state
--   monitors.lua       machine-local monitor layout (gitignored, see setup)
--   local.lua          optional machine-local overrides (gitignored)

require("lua/env")

-- Monitors: a catch-all rule first, then the machine-local file on top.
-- https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
pcall(require, "monitors")

require("lua/look")
require("lua/input")
require("lua/rules")
require("lua/binds")
require("lua/autostart")
require("lua/lockfx")

-- Anything machine-specific that shouldn't be committed goes in local.lua.
pcall(require, "local")
