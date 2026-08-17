# dotfiles

Arch Linux + Hyprland, themed with Catppuccin Mocha end to end — a keyboard-first
desktop tuned for development and for working alongside AI coding agents
(Claude Code, T3 Code).

- **Hyprland** with the new **Lua config** (`hyprland.lua`, Hyprland ≥ 0.55) split
  into small modules — the old `.conf` format is gone
- **waybar** floating islands (workspaces, window title, clock/weather/media,
  status, notifications, power) · **rofi** launcher, window switcher, calc,
  emoji, clipboard, power menu, wallpaper picker, keybind cheatsheet ·
  **swaync** notification center with quick toggles · **swayosd** volume /
  brightness overlay · **hyprlock** HUD-style lock screen with a "hacker mode"
  on wrong passwords (`scripts/lock-fx`) · **hypridle**
  · **hyprsunset** night light · **hyprpolkitagent** · **hyprshutdown**
- **kitty**, **zsh** + starship, **tmux**, **Neovim** (submodule)
- GTK (adw-gtk3-dark + Papirus) and Qt (qt6ct, Catppuccin palette) themed alike

## Install

On a fresh Arch install (a normal user with sudo and an internet connection is
all you need):

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/meszmate/dotfiles/main/setup/arch.sh)
```

The setup is interactive: it first asks a handful of preference questions
(symlink or copy, dev toolchain, AI tools, bluetooth, browser, zsh, services,
login theme, auto-sync — Enter always picks the recommended default), then runs
on its own with numbered `[step/10]` progress and live pacman/yay output.

The script clones this repo to `~/dotfiles` if it isn't there already, then:

1. Installs `base-devel`/`git` and builds the `yay` AUR helper
2. Installs every package the configs need: the Hyprland desktop, PipeWire,
   fonts, tools — plus (optional) the dev toolchain (Node/Bun/pnpm, Python/uv,
   Rust, Go, Java, Elixir, C/C++/Zig, Lua, Docker, git tooling)
3. (optional) AI tools: **Claude Code** (official installer), **T3 Code**
   (AUR), GitHub CLI, and desktop-notification hooks for Claude Code
4. Sets up zsh + oh-my-zsh + autosuggestions/syntax-highlighting, makes zsh the
   login shell; installs tpm (tmux plugin manager)
5. Symlinks all configs into place (`--copy` for independent copies), backing
   up anything that was already there to `~/.dotfiles-backup/<timestamp>/`;
   links `bin/*` into `~/.local/bin`
6. Generates the machine-local files: `~/.config/hypr/monitors.lua`
   (gitignored), the wallpaper symlink, the Qt theme configs
7. Enables NetworkManager (and makes it the *only* network manager — see
   `setup/fix-network`), bluetooth, sddm, power-profiles-daemon, docker
8. Installs the minimal-sddm login theme (frosted glass on the sunset-tree
   artwork; the desktop wallpaper is copied in as an alternative)
9. (optional) Enables the automatic sync timer

Flags: `-y`/`--yes` for fully unattended, `--copy` to copy instead of symlink.

Reboot when it finishes and log in to Hyprland from sddm.
Press `SUPER + /` at any time for the searchable keybind cheatsheet.

## Keybinds (Hyprland)

`SUPER` is the main modifier. Every bind has a description, so `SUPER + /`
lists all of them (`hyprctl binds -j` is the source of truth).

| Keys | Action |
| --- | --- |
| `SUPER + Return` | Terminal (kitty) |
| `SUPER + Space` | App launcher (rofi) · `SUPER + R` run a command |
| `ALT + Tab` | Window switcher |
| `SUPER + B` / `SUPER + E` | Browser (zen) / file manager (thunar) |
| `SUPER + C` | Clipboard history (Del removes an entry) |
| `SUPER + ,` / `SUPER + =` | Emoji picker / calculator |
| `SUPER + /` | Keybind cheatsheet |
| `SUPER + `` ` `` | Scratchpad terminal (persistent tmux session) |
| `SUPER + A` | "Agent" workspace — a second scratchpad for claude / t3code |
| `SUPER + T` | T3 Code |
| `SUPER + Q` | Close window |
| `SUPER + H/J/K/L` (or arrows) | Move focus |
| `SUPER + SHIFT + H/J/K/L` | Move window |
| `SUPER + CTRL + H/J/K/L` | Resize · `SUPER + ALT + R` sticky resize mode |
| `SUPER + 1..0` | Switch workspace (`+ SHIFT` move window, `+ CTRL + SHIFT` move silently) |
| `SUPER + Tab` / `SUPER + -` | Next workspace / last workspace |
| `SUPER + [` / `]` | Focus monitor left / right (`+ SHIFT` moves the window) |
| `SUPER + V` / `F` / `SHIFT + F` / `P` / `N` | Float / maximize / fullscreen / pseudotile / toggle split |
| `SUPER + G` · `SUPER + ALT + H/L` | Toggle window group · previous / next tab in group |
| `SUPER + SHIFT + P` / `SHIFT + V` | Pin / center a floating window |
| `SUPER + S` / `SUPER + SHIFT + S` | Region screenshot → annotate (swappy) / → clipboard |
| `Print` / `SUPER + Print` / `SUPER + CTRL + S` | Screen → clipboard / window → clipboard / screenshot menu |
| `SUPER + SHIFT + R` | Screen recording toggle (→ ~/Videos/Recordings) |
| `SUPER + SHIFT + C` | Colour picker → clipboard |
| `SUPER + SHIFT + W` | Wallpaper picker (~/Pictures/Wallpapers) |
| `SUPER + SHIFT + N` / `SUPER + SHIFT + D` | Notification center / do-not-disturb |
| `SUPER + SHIFT + B` / `SUPER + SHIFT + T` | Toggle bar / night light |
| `SUPER + .` | Lock screen |
| `SUPER + Esc` | Power menu (lock, suspend, log out, reboot, shut down) |
| `SUPER + SHIFT + Q` | Log out gracefully (hyprshutdown) |
| `SUPER + CTRL + X` / `SUPER + CTRL + R` | Shut down / reboot gracefully |
| `SUPER + drag` / `SUPER + right-drag` | Move / resize windows with the mouse |
| 3-finger swipe | Switch workspaces (4-finger down: scratchpad, up: fullscreen) |

Volume, brightness, and media hardware keys work out of the box (with an OSD)
and also on the lock screen. Idle: dim at 5 min, lock at 10, displays off at
15, suspend at 30 — but only on battery, so long jobs on AC survive.

### Lock screen

`hyprlock.conf` is a HUD: clock top-left, a panel with a big lock glyph, the
word **LOCKED**, the password field (`▌ enter password` → `VERIFYING…` →
`ACCESS DENIED · strike n`) and `user@host · layout`; battery/network/host and
now-playing at the bottom. Animations are off, so locking and unlocking are
instant. A wrong password puts the screen into "hacker mode", driven by
`config/hypr/scripts/lock-fx`: the wallpaper hard-cuts to a red scan-lined
copy, LOCKED glitch-decodes into ACCESS DENIED with a strike counter and a
countermeasures bar, an intrusion log types out bottom-left and a hex stream
keeps running bottom-right. It stays that way until you start typing again —
the compositor sees the keypress (`lua/lockfx.lua`) and resets the screen so
you retry on a calm HUD. Ticks slow down after a minute and stop after ten, so
walking away costs nothing. Both wallpapers are pre-rendered by `lock-fx
prepare` (run at login, before locking, and by the wallpaper picker) into
`~/.cache/hyprlock`.
`scripts/lock` is what `SUPER + .` / hypridle call: it checks `hyprctl locked`
and clears stale hyprlock instances instead of relying on `pidof`.

### Login screen

`setup/minimal-sddm/` is a Qt6 SDDM theme with its own look — the sharp
sunset-tree artwork (`tree.png`) with frosted-glass controls, no dark panels:
a glass avatar circle (picture or initial), the user's name, a glass password
pill, and small chips for the session and keyboard layout; clock top-right,
host + `F1 help` bottom-left, suspend / restart / power off bottom-right. Users
are switchable (‹ › or ↑ ↓ / F2 cycle; click the name or press Enter on it
for a picker with an "Other user…" entry to type a login name), the session
chip opens a picker, the layout chip cycles layouts, the eye shows the
password, caps lock is called out, and everything is reachable with Tab. A
wrong password turns the pill red, shakes it, flashes the screen briefly and
shows "Wrong password · attempt n"; while PAM checks an arc spins around the
avatar. Popups and the help sheet are light cards. Colours, fonts, blur, pill
size and the background are in `theme.conf` (`install-sddm-theme` also copies
the desktop wallpaper in as `wallpaper.jpg`; set `background=wallpaper.jpg` to
use it). Preview without logging out:
`sddm-greeter-qt6 --test-mode --theme setup/minimal-sddm` (in test mode the
password `sddm` succeeds, anything else fails).

## The Hyprland Lua config

`config/hypr/hyprland.lua` just requires the modules in `config/hypr/lua/`:

| File | What |
| --- | --- |
| `theme.lua` | Catppuccin Mocha palette (`C.rgb("mauve")`, `C.gradient(...)`) |
| `apps.lua` | terminal / browser / menus used by binds — change programs here |
| `env.lua` | environment variables (restart Hyprland to apply) |
| `look.lua` | gaps, borders, rounding, blur, shadows, animations, layouts |
| `input.lua` | keyboard, touchpad, gestures |
| `rules.lua` | window / layer / workspace rules (scratchpads live here) |
| `binds.lua` | keybinds — `bind(keys, dispatcher, "description")` |
| `autostart.lua` | programs started with the session |
| `monitors.lua` | *machine-local*, gitignored — see `monitors.lua.example` |
| `local.lua` | *optional, gitignored* — machine-specific overrides |

Each `require()` runs in its own scope, so a typo in one file doesn't take the
others down; Hyprland reloads on save. `.luarc.json` points lua-language-server
at the shipped API stubs, so Neovim (lua_ls) completes `hl.*`.
`hyprctl repl` is a live Lua REPL into the compositor.

## Working with agents

- **Claude Code** — installed by setup; `~/.claude/settings.json` gets hooks that
  send a desktop notification when Claude needs input or finishes while you're
  in another window (`bin/claude-notify`, wired by `setup/claude-hooks-install`).
- **T3 Code** — `SUPER + T` (or the launcher); drives the `claude` CLI.
- `SUPER + A` toggles an *agent* scratchpad (kitty in a persistent tmux session
  `agent`) that floats over any workspace; `SUPER + `` ` `` is a second one.
- kitty notifies when a command that ran > 20 s finishes in a window you are not
  looking at.
- Shell aliases: `cc` (claude), `ccc` (`--continue`), `ccr` (`--resume`), `t3`.

## Layout

```
config/           → symlinked into ~/.config/
  hypr/           hyprland.lua + lua/ modules, hyprlock, hypridle, hyprpaper,
                  hyprsunset, hyprtoolkit theme, scripts/ (lock, lock-fx,
                  screenshot, record, nightlight, lockinfo)
  waybar/         bar config, style, scripts (weather, updates)
  rofi/           launcher config + theme, scripts/ (powermenu, clipboard,
                  keybinds, wallpaper)
  swaync/         notification center config + style
  swayosd/        OSD config + style
  kitty/          kitty + Catppuccin Mocha
  qt6ct/ qt5ct/   Qt theme (palette + generated .conf)
  gtk-3.0/4.0/    dark GTK theme (adw-gtk3-dark + Papirus icons)
  nvim/           Neovim (git submodule → meszmate/nvim)
  tmux/           tmux + tpm plugins
  starship.toml   prompt
home/             → symlinked into ~/ (.zshrc, ...)
bin/              → symlinked into ~/.local/bin (claude-notify)
setup/
  arch.sh              the installer
  fix-network          make NetworkManager the only network manager
  install-sddm-theme   (re)install the login theme (copies the wallpaper in too)
  claude-hooks-install add the Claude Code notification hooks
  minimal-sddm/        sddm login theme (Qt6 QML, frosted glass on tree.png)
```

## Automatic sync

If enabled during install, a systemd user timer (`dotfiles-sync.timer`) runs
3 minutes after boot and every 6 hours: it pulls this repo (fast-forward
only), updates the nvim submodule, installs any packages newly added to
`setup/arch.sh`, links any new configs, and updates the system — then sends a
notification and reloads Hyprland. Symlinked configs need no sync at all;
edits apply instantly.

Run `dotfiles-sync` manually anytime; logs go to
`~/.local/state/dotfiles-sync.log`. It uses a scoped sudoers rule
(`/etc/sudoers.d/11-dotfiles-sync`, passwordless `pacman` only) so the timer
can install packages unattended — delete that file to revoke it.

## After installing

- Edit `~/.config/hypr/monitors.lua` for your monitor layout
  ([wiki](https://wiki.hypr.land/Configuring/Basics/Monitors/))
- Put wallpapers in `~/Pictures/Wallpapers` and pick one with `SUPER + SHIFT + W`;
  `setup/install-sddm-theme` copies it into the login theme too (see `theme.conf`)
- Weather: metric by default; set `WEATHER_UNIT=F` / `WEATHER_LOCATION=...` in
  the waybar `custom/weather` exec line to change
- First `nvim` start installs all plugins and language servers automatically
- In tmux, `ctrl-a + I` installs the tmux plugins once
- `claude` once to log in
