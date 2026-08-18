# Working in this repo (for AI agents and humans)

These dotfiles must reproduce the same desktop on **any** machine from a fresh
Arch install with `setup/arch.sh`. Everything below follows from that.

## Rules

1. **Every package you install goes into `setup/arch.sh`.** If you `pacman -S`
   / `yay -S` something (a tool, a font, a Python/GTK library, a Qt module…),
   add it to the matching array in the same commit: `CORE_PKGS` (needed by the
   desktop / configs shipped here), `DEV_PKGS` (languages & dev tooling),
   `AI_PKGS` / `AI_AUR_PKGS`, `BT_PKGS`, `BROWSER_AUR_PKGS`. Put a short comment
   on what needs it. Nothing may depend on something that is only installed
   locally.
2. **Every config lives in the repo, not only in `~`.** `config/*` is symlinked
   to `~/.config/*` and `home/.*` to `~/.*` by the installer, so write there
   (a new `config/<app>/` directory is picked up automatically). Scripts go to
   `config/hypr/scripts/`, `config/rofi/scripts/`, `config/waybar/scripts/` or
   `bin/` (→ `~/.local/bin`). Anything else the installer must do (services,
   ACLs, symlinks outside `~/.config`) is a step in `setup/arch.sh` or a script
   in `setup/`.
3. **Document it.** New feature → README (and the keybind gets a description,
   see below). Machine-specific values go in gitignored files
   (`monitors.lua`, `local.lua`), never hard-coded.
4. `~/.config/*` **are live symlinks** into this repo — editing a file changes
   the running session immediately (Hyprland reloads on save). Test, don't
   guess; keep changes small.
5. `config/nvim` is a **git submodule** (`meszmate/nvim`) — commit changes there
   separately and then bump the pointer here.

## Conventions

- Theme is **Catppuccin Mocha** everywhere (palette in `config/hypr/lua/theme.lua`,
  `config/waybar/style.css`, `config/rofi/theme.rasi`). The SDDM theme
  (`setup/minimal-sddm`) is the one deliberate exception (light frosted glass on
  the tree artwork).
- Keybinds: `config/hypr/lua/binds.lua`, `group("Section")` then
  `bind(keys, dispatcher, "What it does")`. Descriptions become
  `"Section · What it does"` in `hyprctl binds -j`, which is what the cheatsheet
  overlay (`bin/keybinds`, `SUPER + /`) renders. Every bind needs a
  description; programs are referenced through `lua/apps.lua`.
- tmux keybinds (`config/tmux/tmux.reset.conf`) use the same convention:
  `bind -N "Section · What it does" key cmd` — `keybinds tmux` (`prefix + ?`)
  reads them with `tmux list-keys -N`; plugin binds are recognised by script.
- Fonts: Inter (UI) and JetBrainsMono Nerd Font (mono / icons).
- Shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, header comment
  saying what it is for and how it is invoked.

## Testing tips

- Hyprland: `hyprctl reload` (Lua config errors show in `hyprctl rollinglog`).
- The desktop shell (waybar, swaync, hypridle, hyprpaper, hyprsunset,
  hyprpolkitagent, swayosd) runs as systemd --user units started by
  `lua/autostart.lua` (`Restart=on-failure`): `systemctl --user restart waybar`,
  `journalctl --user -u waybar`. `pkill -SIGUSR2 waybar` reloads its config;
  CSS reloads on save.
- SDDM theme: `sddm-greeter-qt6 --test-mode --theme setup/minimal-sddm`
  (password `sddm` fakes success; QML errors go to
  `journalctl _COMM=sddm-greeter-qt`; kill with `pkill -x sddm-greeter-qt`).
- Overlays/scripts: `grim -g "x,y wxh" out.png` to screenshot, `wtype` to send keys.
- Never `pkill -f` / `pgrep -f` with a pattern that also appears in your own
  command line — it kills the shell running it.
- Neovim: `nvim --headless "+checkhealth nvim-treesitter" +qa`, `:TSUpdate`.
