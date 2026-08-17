-- Keyboard, touchpad, mouse and gestures.
-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "caps:swapescape",   -- Caps Lock <-> Escape (vim)
        kb_rules   = "",
        numlock_by_default = false,
        repeat_rate  = 35,
        repeat_delay = 300,

        follow_mouse = 1,
        sensitivity  = 0,     -- -1.0 .. 1.0, 0 = no change
        accel_profile = "",   -- "flat" for no acceleration (gaming mice)

        touchpad = {
            natural_scroll       = false,
            tap_to_click         = true,
            disable_while_typing = true,
            clickfinger_behavior = true,  -- 2-finger click = right click, 3 = middle
            scroll_factor        = 1.0,
        },
    },
    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_cancel_ratio = 0.3,
    },
})

-- 3-finger horizontal swipe switches workspaces (1:1 gesture)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- 4-finger swipe down toggles the scratchpad terminal
hl.gesture({ fingers = 4, direction = "down", action = "special", workspace_name = "scratch" })
-- 4-finger swipe up: fullscreen the active window
hl.gesture({ fingers = 4, direction = "up", action = "fullscreen" })

-- Per-device tweaks: hyprctl devices lists the names.
-- hl.device({ name = "logitech-pro-x-2", sensitivity = -0.3, accel_profile = "flat" })
