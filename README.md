# dotfiles

Arch Linux + Hyprland setup, themed with Catppuccin Mocha end to end
(Hyprland, waybar, kitty, tmux, starship, hyprlock, Neovim).

## Install

On a fresh Arch install (a normal user with sudo and an internet connection is
all you need):

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/meszmate/dotfiles/main/setup/arch.sh)
```

The setup is interactive: it first asks a handful of preference questions
(symlink or copy, dev toolchain, bluetooth, browser, zsh, services, login
theme — Enter always picks the recommended default), then runs everything on
its own with numbered `[step/8]` progress and live pacman/yay output.

The script clones this repo to `~/dotfiles` if it isn't there already, then:

1. Installs `base-devel`/`git` and builds the `yay` AUR helper
2. Installs every package the configs need (official repos + AUR), including
   the Hyprland desktop, PipeWire audio, fonts, and a full dev toolchain
   (Neovim, Node, Rust, Go, Java, Elixir)
3. Sets up zsh + oh-my-zsh + autosuggestions/syntax-highlighting and makes
   zsh your login shell
4. Installs tpm (tmux plugin manager)
5. Symlinks all configs into place (`--copy` for independent copies), backing
   up anything that was already there to `~/.dotfiles-backup/<timestamp>/`
6. Generates a machine-local `~/.config/hypr/monitors.conf` (gitignored)
7. Enables NetworkManager, bluetooth, and sddm
8. Installs the minimal-sddm login theme

Flags: `-y`/`--yes` for fully unattended, `--copy` to copy instead of symlink.

Reboot when it finishes and log in to Hyprland from sddm.

## Keybinds (Hyprland)

`SUPER` is the main modifier.

| Keys | Action |
| --- | --- |
| `SUPER + Return` | Terminal (kitty) |
| `SUPER + Space` | App launcher (wofi) |
| `SUPER + B` / `SUPER + E` | Browser (zen) / file manager (thunar) |
| `SUPER + Q` | Close window |
| `SUPER + H/J/K/L` | Move focus (vim-style) |
| `SUPER + SHIFT + H/J/K/L` | Move window |
| `SUPER + CTRL + H/J/K/L` | Resize window |
| `SUPER + 1..0` | Switch workspace (`+ SHIFT` to move window) |
| `SUPER + S` / `Print` | Region screenshot → swappy / full screen → clipboard |
| `SUPER + SHIFT + R` | Screen recording toggle (wf-recorder → ~/Videos) |
| `SUPER + SHIFT + C` | Color picker (hyprpicker → clipboard) |
| `SUPER + C` | Clipboard history (cliphist) |
| `SUPER + .` | Lock screen (hyprlock) |
| `SUPER + V` / `F` / `P` / `N` | Float / fullscreen / pseudotile / toggle split |

Volume, brightness, and media hardware keys all work out of the box.
Idle behavior (hypridle): dim at 5 min, lock at 10, displays off at 15.

## Layout

```
config/         → symlinked into ~/.config/
  hypr/         Hyprland, hyprlock, hypridle, wallpaper
  kitty/        kitty + Catppuccin Mocha
  wofi/         launcher theme
  mako/         notification theme
  gtk-3.0/4.0/  dark GTK theme (adw-gtk3-dark + Papirus icons)
  nvim/         Neovim (git submodule → meszmate/nvim)
  tmux/         tmux + tpm plugins
  waybar/       bar config, style, scripts (updates, weather)
  starship.toml prompt
home/           → symlinked into ~/ (.zshrc, ...)
setup/
  arch.sh       the installer
  minimal-sddm/ sddm login theme (Qt6)
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

- Edit `~/.config/hypr/monitors.conf` for your monitor layout
  ([wiki](https://wiki.hypr.land/Configuring/Monitors/))
- First `nvim` start installs all plugins and language servers automatically
- In tmux, `ctrl-a + I` installs the tmux plugins once
