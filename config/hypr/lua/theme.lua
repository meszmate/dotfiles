-- Catppuccin Mocha palette shared by the Hyprland modules.
-- Other files: local C = require("lua/theme")
--
-- Every entry is a plain hex string ("cba6f7") so it can be dropped into any
-- Hyprland colour form: C.rgb("mauve") -> "rgb(cba6f7)",
-- C.rgba("mauve", 0.8) -> "rgba(cba6f7cc)".

local C = {
    rosewater = "f5e0dc",
    flamingo  = "f2cdcd",
    pink      = "f5c2e7",
    mauve     = "cba6f7",
    red       = "f38ba8",
    maroon    = "eba0ac",
    peach     = "fab387",
    yellow    = "f9e2af",
    green     = "a6e3a1",
    teal      = "94e2d5",
    sky       = "89dceb",
    sapphire  = "74c7ec",
    blue      = "89b4fa",
    lavender  = "b4befe",
    text      = "cdd6f4",
    subtext1  = "bac2de",
    subtext0  = "a6adc8",
    overlay2  = "9399b2",
    overlay1  = "7f849c",
    overlay0  = "6c7086",
    surface2  = "585b70",
    surface1  = "45475a",
    surface0  = "313244",
    base      = "1e1e2e",
    mantle    = "181825",
    crust     = "11111b",
}

--- "rgb(rrggbb)" for a palette name.
function C.rgb(name)
    return "rgb(" .. C[name] .. ")"
end

--- "rgba(rrggbbaa)" for a palette name and an alpha in 0..1.
function C.rgba(name, alpha)
    local a = math.floor((alpha or 1) * 255 + 0.5)
    return string.format("rgba(%s%02x)", C[name], a)
end

--- Two-colour gradient table accepted by border/shadow/glow options.
function C.gradient(a, b, angle, alpha)
    return { colors = { C.rgba(a, alpha or 1), C.rgba(b, alpha or 1) }, angle = angle or 45 }
end

return C
