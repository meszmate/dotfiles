-- Lock-screen "hacker mode" support (config/hypr/scripts/lock-fx).
-- After a wrong password the lock screen stays in its alarm state; the first
-- key pressed afterwards ends it. hyprlock can't report keypresses, but the
-- compositor sees them even while the session is locked. lock-fx creates
-- $XDG_RUNTIME_DIR/hyprlock-fx/armed on a failure; we drop it on the next
-- key press and call `lock-fx retry` (one spawn per failure, nothing otherwise).

local dir    = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hyprlock-fx"
local armed  = dir .. "/armed"
local script = os.getenv("HOME") .. "/.config/hypr/scripts/lock-fx"

hl.on("input.keyboard.key", function(_, _, state)
    if state ~= 1 then return end            -- presses only (0 = release, 2 = repeat)
    local f = io.open(armed, "r")
    if not f then return end
    f:close()
    os.remove(armed)
    hl.exec_cmd(script .. " retry")
end)
