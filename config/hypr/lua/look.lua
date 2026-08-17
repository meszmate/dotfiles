-- Look & feel: gaps, borders, rounding, blur, shadows, animations, layouts.
-- https://wiki.hypr.land/Configuring/Basics/Variables/

local C = require("lua/theme")

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,
        col = {
            active_border   = C.gradient("mauve", "blue", 45, 0.95),
            inactive_border = C.rgba("surface1", 0.7),
        },
        layout           = "dwindle",
        resize_on_border = true,   -- drag window edges/gaps to resize
        extend_border_grab_area = 12,
        allow_tearing    = false,
        snap = { enabled = true, window_gap = 12, monitor_gap = 12 },
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2.5,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive = false,

        shadow = {
            enabled      = true,
            range        = 16,
            render_power = 3,
            color          = C.rgba("crust", 0.9),
            color_inactive = C.rgba("crust", 0.5),
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 3,
            noise    = 0.01,
            vibrancy = 0.17,
            popups   = true,
            popups_ignorealpha = 0.6,
            new_optimizations  = true,
        },
    },

    group = {
        col = {
            border_active   = C.gradient("mauve", "lavender", 45, 0.95),
            border_inactive = C.rgba("surface1", 0.7),
            border_locked_active   = C.gradient("peach", "red", 45, 0.95),
            border_locked_inactive = C.rgba("surface1", 0.7),
        },
        groupbar = {
            enabled       = true,
            font_family   = "Inter",
            font_size     = 11,
            height        = 20,
            gradients     = false,
            render_titles = true,
            rounding      = 8,
            text_color    = C.rgb("text"),
            col = {
                active   = C.rgba("mauve", 0.6),
                inactive = C.rgba("surface0", 0.7),
                locked_active   = C.rgba("peach", 0.6),
                locked_inactive = C.rgba("surface0", 0.7),
            },
        },
    },

    dwindle = {
        preserve_split       = true,  -- needed for the togglesplit layoutmsg
        special_scale_factor = 0.9,   -- scratchpad windows float over the desktop a bit smaller
    },
    master = { new_status = "master" },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        font_family             = "Inter",
        vrr                     = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
        animate_manual_resizes  = false,
        animate_mouse_windowdragging = false,
        allow_session_lock_restore = true,  -- if hyprlock crashes, a new one can take over
        background_color        = C.rgb("crust"),
    },

    binds = {
        workspace_back_and_forth = true,  -- SUPER+n on the current workspace jumps back
        allow_workspace_cycles   = true,
        movefocus_cycles_fullscreen = true,
    },

    cursor = {
        hide_on_key_press = true,
        inactive_timeout  = 0,
    },

    xwayland = { force_zero_scaling = true },

    ecosystem = {
        no_update_news   = false,
        no_donation_nag  = false,
    },
})

-- Animations -----------------------------------------------------------------
hl.config({ animations = { enabled = true, workspace_wraparound = false } })

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })
