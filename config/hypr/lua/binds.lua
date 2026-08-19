-- Keybinds. Every bind carries a description ("Section · What it does") so
-- bin/keybinds (SUPER+/, or 󰌌 in waybar) can render a searchable
-- cheatsheet grouped into cards straight from `hyprctl binds -j`.
-- https://wiki.hypr.land/Configuring/Basics/Binds/
-- https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local apps = require("lua/apps")
local mod  = "SUPER"

local section = "Other"
local function group(name) section = name end

local function bind(keys, dispatcher, desc, flags)
    local opts = flags or {}
    opts.description = section .. " · " .. desc
    return hl.bind(keys, dispatcher, opts)
end

local function run(cmd) return hl.dsp.exec_cmd(cmd) end

-- Apps & menus ---------------------------------------------------------------
group("Apps & menus")
bind(mod .. " + RETURN",       run(apps.terminal),   "Terminal")
bind(mod .. " + E",            run(apps.files),      "File manager")
bind(mod .. " + B",            run(apps.browser),    "Browser")
bind(mod .. " + SPACE",        run(apps.launcher),   "App launcher")
bind(mod .. " + T",            run(apps.t3code),     "T3 Code (AI agent IDE)")
bind(mod .. " + R",            run(apps.run),        "Run a command")
bind("ALT + TAB",              run(apps.windows),    "Window switcher")
bind(mod .. " + C",            run(apps.clipboard),  "Clipboard history")
bind(mod .. " + comma",        run(apps.emoji),      "Emoji picker")
bind(mod .. " + equal",        run(apps.calc),       "Calculator")
bind(mod .. " + slash",        run(apps.cheatsheet), "Keybind cheatsheet")
bind(mod .. " + SHIFT + W",    run(apps.wallpapers), "Wallpaper picker")

-- Session --------------------------------------------------------------------
group("Session")
bind(mod .. " + period",       run("pgrep -x hypridle >/dev/null && loginctl lock-session || " .. apps.scripts .. "/lock"), "Lock screen")
bind(mod .. " + I",            run(apps.idle .. " toggle"), "Idle mode: normal → awake → presentation")
bind(mod .. " + SHIFT + I",    run(apps.idle .. " menu"),   "Idle mode menu")
bind(mod .. " + escape",       run(apps.powermenu), "Power menu")
bind(mod .. " + SHIFT + Q",    run(apps.logout),    "Log out (graceful)")
bind(mod .. " + CTRL + X",     run(apps.poweroff),  "Shut down (graceful)")
bind(mod .. " + CTRL + R",     run(apps.reboot),    "Reboot (graceful)")

-- Notifications (swaync) -----------------------------------------------------
group("Notifications")
bind(mod .. " + SHIFT + N",    run("swaync-client -t -sw"), "Notification center")
bind(mod .. " + SHIFT + D",    run("swaync-client -d -sw"), "Do not disturb toggle")

-- Screenshots, recording, colours -------------------------------------------
group("Capture")
bind(mod .. " + S",            run(apps.screenshot .. " region edit"),   "Screenshot region, annotate")
bind(mod .. " + SHIFT + S",    run(apps.screenshot .. " region copy"),   "Screenshot region to clipboard")
bind("Print",                  run(apps.screenshot .. " output copy"),   "Screenshot screen to clipboard")
bind(mod .. " + Print",        run(apps.screenshot .. " window copy"),   "Screenshot window to clipboard")
bind(mod .. " + CTRL + S",     run(apps.screenshot .. " menu"),          "Screenshot menu")
bind(mod .. " + SHIFT + R",    run(apps.record),                         "Screen recording toggle")
bind(mod .. " + SHIFT + C",    run(apps.colorpicker),                    "Colour picker to clipboard")

-- Windows --------------------------------------------------------------------
group("Windows")
bind(mod .. " + Q",            hl.dsp.window.close(),                         "Close window")
bind(mod .. " + V",            hl.dsp.window.float({ action = "toggle" }),    "Toggle floating")
bind(mod .. " + F",            hl.dsp.window.fullscreen({ mode = "maximized" }), "Toggle maximize")
bind(mod .. " + SHIFT + F",    hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
bind(mod .. " + P",            hl.dsp.window.pseudo(),                        "Toggle pseudotile")
bind(mod .. " + N",            hl.dsp.layout("togglesplit"),                  "Toggle split direction")
bind(mod .. " + SHIFT + P",    hl.dsp.window.pin(),                           "Pin floating window")
bind(mod .. " + SHIFT + V",    hl.dsp.window.center(),                        "Center floating window")
bind(mod .. " + G",            hl.dsp.group.toggle(),                         "Toggle window group")
bind(mod .. " + ALT + H",      hl.dsp.group.prev(),                           "Group: previous tab")
bind(mod .. " + ALT + L",      hl.dsp.group.next(),                           "Group: next tab")

-- Focus & move (vim keys and arrows)
group("Focus & move")
local dirs = { l = "left", r = "right", u = "up", d = "down" }
for key, dir in pairs({ H = "l", L = "r", K = "u", J = "d", left = "l", right = "r", up = "u", down = "d" }) do
    bind(mod .. " + " .. key,           hl.dsp.focus({ direction = dir }),         "Focus window " .. dirs[dir])
    bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ direction = dir }),   "Move window " .. dirs[dir])
end
group("Resize")
bind(mod .. " + CTRL + H",     hl.dsp.window.resize({ x = -30, y = 0,  relative = true }), "Resize left", { repeating = true })
bind(mod .. " + CTRL + L",     hl.dsp.window.resize({ x = 30,  y = 0,  relative = true }), "Resize right", { repeating = true })
bind(mod .. " + CTRL + K",     hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), "Resize up", { repeating = true })
bind(mod .. " + CTRL + J",     hl.dsp.window.resize({ x = 0,   y = 30, relative = true }), "Resize down", { repeating = true })

-- Resize submap: SUPER+ALT+R, then hjkl/arrows, ESC/Return to leave
bind(mod .. " + ALT + R", hl.dsp.submap("resize"), "Resize mode")
hl.define_submap("resize", function()
    for key, d in pairs({ H = { -30, 0 }, L = { 30, 0 }, K = { 0, -30 }, J = { 0, 30 },
                          left = { -30, 0 }, right = { 30, 0 }, up = { 0, -30 }, down = { 0, 30 } }) do
        hl.bind(key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
    end
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("RETURN", hl.dsp.submap("reset"))
    hl.bind("catchall", hl.dsp.no_op())
end)

-- Monitors
group("Monitors")
bind(mod .. " + bracketleft",          hl.dsp.focus({ monitor = "l" }),         "Focus monitor left")
bind(mod .. " + bracketright",         hl.dsp.focus({ monitor = "r" }),         "Focus monitor right")
bind(mod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ monitor = "l" }),   "Move window to monitor left")
bind(mod .. " + SHIFT + bracketright", hl.dsp.window.move({ monitor = "r" }),   "Move window to monitor right")

-- Mouse
group("Mouse")
bind(mod .. " + mouse:272", hl.dsp.window.drag(),   "Drag window",   { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })
bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Next workspace (scroll)")
bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), "Previous workspace (scroll)")

-- Workspaces -----------------------------------------------------------------
group("Workspaces")
for i = 1, 10 do
    local key = tostring(i % 10)
    bind(mod .. " + " .. key,                hl.dsp.focus({ workspace = i }),                       "Workspace " .. i)
    bind(mod .. " + SHIFT + " .. key,        hl.dsp.window.move({ workspace = i, follow = true }),   "Move window to workspace " .. i)
    bind(mod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }),  "Send to workspace " .. i .. ", stay here")
end
bind(mod .. " + TAB",         hl.dsp.focus({ workspace = "e+1" }),      "Next workspace")
bind(mod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }),      "Previous workspace")
bind(mod .. " + minus",       hl.dsp.focus({ workspace = "previous" }), "Last workspace")

-- Scratchpads (special workspaces). Empty ones auto-spawn a terminal, see rules.lua
group("Scratchpads")
bind(mod .. " + grave",         hl.dsp.workspace.toggle_special("scratch"),           "Scratchpad terminal")
bind(mod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratch" }), "Move window to scratchpad")
bind(mod .. " + A",             hl.dsp.workspace.toggle_special("agent"),             "Agent workspace (claude/t3code)")
bind(mod .. " + SHIFT + A",     hl.dsp.window.move({ workspace = "special:agent" }),   "Move window to agent workspace")

-- Bar / night light -----------------------------------------------------------
group("Bar & display")
bind(mod .. " + SHIFT + B", run("pkill -SIGUSR1 waybar"),                       "Toggle bar")
bind(mod .. " + SHIFT + T", run(apps.scripts .. "/nightlight toggle"),          "Night light toggle")

-- Hardware keys (also work on the lock screen) --------------------------------
group("Hardware keys")
local osd = "swayosd-client"
bind("XF86AudioRaiseVolume",  run(osd .. " --output-volume raise"),      "Volume up",        { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  run(osd .. " --output-volume lower"),      "Volume down",      { locked = true, repeating = true })
bind("XF86AudioMute",         run(osd .. " --output-volume mute-toggle"), "Mute",            { locked = true })
bind("XF86AudioMicMute",      run(osd .. " --input-volume mute-toggle"),  "Mute microphone", { locked = true })
bind("XF86MonBrightnessUp",   run(osd .. " --brightness raise"),         "Brightness up",    { locked = true, repeating = true })
bind("XF86MonBrightnessDown", run(osd .. " --brightness lower"),         "Brightness down",  { locked = true, repeating = true })
bind("XF86AudioPlay",         run("playerctl play-pause"),  "Play / pause",   { locked = true })
bind("XF86AudioPause",        run("playerctl play-pause"),  "Play / pause",   { locked = true })
bind("XF86AudioNext",         run("playerctl next"),        "Next track",     { locked = true })
bind("XF86AudioPrev",         run("playerctl previous"),    "Previous track", { locked = true })
