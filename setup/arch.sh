#!/usr/bin/env bash
# ============================================================
#  Arch Linux bootstrap for meszmate/dotfiles
#
#  Works on a completely fresh Arch install (only needs a
#  regular user with sudo and an internet connection):
#
#    bash <(curl -fsSL https://raw.githubusercontent.com/meszmate/dotfiles/main/setup/arch.sh)
#
#  or, if the repo is already cloned:
#
#    ~/dotfiles/setup/arch.sh
#
#  Flags:
#    -y, --yes    non-interactive, answer yes to everything
#    --copy       copy config files instead of symlinking them
# ============================================================

set -Eeuo pipefail

REPO_URL="https://github.com/meszmate/dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CONFIG_DIR="$DOTFILES_DIR/config"
HOMEFILES_DIR="$DOTFILES_DIR/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
INSTLOG="$HOME/dotfiles-install.log"

ASSUME_YES=0
INSTALL_MODE="symlink"

ok()   { printf '  \e[1;32m✔\e[0m %s\n' "$*"; }
warn() { printf '  \e[1;33m⚠\e[0m %s\n' "$*"; }
err()  { printf '  \e[1;31m✘\e[0m %s\n' "$*" >&2; }
note() { printf '  \e[1;34m➜\e[0m %s\n' "$*"; }
section() { printf '\n\e[1;35m==> %s\e[0m\n' "$*"; }

trap 'err "Setup failed at line $LINENO. Details: $INSTLOG"' ERR

usage() { sed -n '2,17p' "$0"; exit 0; }

for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    --copy)   INSTALL_MODE="copy" ;;
    -h|--help) usage ;;
    *) err "Unknown option: $arg"; exit 1 ;;
  esac
done

# Ask a yes/no question; plain Enter means yes.
ask() {
  [[ $ASSUME_YES -eq 1 ]] && return 0
  local answer
  read -rp "$(printf '  \e[1;33m?\e[0m %s [Y/n] ' "$1")" answer
  [[ ! $answer =~ ^[Nn] ]]
}

# ------------------------------------------------------------
# Sanity checks
# ------------------------------------------------------------
echo "============================================"
echo "   Arch Linux setup — meszmate/dotfiles"
echo "============================================"

[[ -f /etc/arch-release ]] || { err "This script is for Arch Linux only."; exit 1; }
[[ $EUID -ne 0 ]] || { err "Run as your normal user, not root (sudo is used when needed)."; exit 1; }

: > "$INSTLOG"
note "Full command output is logged to $INSTLOG"

note "Asking for sudo up front (kept alive for the whole run)..."
sudo -v
( while sudo -n true 2>/dev/null; do sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &

# ------------------------------------------------------------
# Base tools + clone the repo itself if missing
# ------------------------------------------------------------
section "Base tools (git, base-devel)"
sudo pacman -Sy --needed --noconfirm base-devel git >>"$INSTLOG" 2>&1
ok "base-devel and git present"

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  section "Cloning dotfiles to $DOTFILES_DIR"
  git clone --recurse-submodules "$REPO_URL" "$DOTFILES_DIR" >>"$INSTLOG" 2>&1
  ok "Repository cloned"
fi
git -C "$DOTFILES_DIR" submodule update --init >>"$INSTLOG" 2>&1 || warn "Could not update the nvim submodule (check network)."

# ------------------------------------------------------------
# AUR helper (yay)
# ------------------------------------------------------------
section "AUR helper"
if command -v yay >/dev/null; then
  ok "yay already installed"
else
  note "Building yay-bin from the AUR..."
  YAY_TMP=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$YAY_TMP" >>"$INSTLOG" 2>&1
  ( cd "$YAY_TMP" && makepkg -si --noconfirm >>"$INSTLOG" 2>&1 )
  rm -rf "$YAY_TMP"
  ok "yay installed"
fi

# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------
PACMAN_PKGS=(
  # Hyprland desktop
  hyprland hyprlock hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  qt5-wayland qt6-wayland polkit-gnome
  waybar wofi mako libnotify swww grim slurp swappy wl-clipboard cliphist
  # Terminal, shell & CLI tools
  kitty zsh starship tmux fzf zoxide eza bat fd ripgrep lazygit btop
  man-db unzip wget
  # Audio
  pipewire pipewire-alsa pipewire-pulse wireplumber pamixer pavucontrol playerctl
  # Network & bluetooth
  networkmanager network-manager-applet bluez bluez-utils blueman
  # Files
  thunar thunar-archive-plugin file-roller gvfs
  # System utilities
  brightnessctl pacman-contrib python-requests xdg-user-dirs
  # Development
  neovim nodejs npm rustup go jdk-openjdk erlang elixir
  # Fonts
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji inter-font
  # Login manager (theme needs the qt6 modules)
  sddm qt6-svg qt6-5compat qt6-declarative
  # GTK theming
  nwg-look adw-gtk-theme papirus-icon-theme adwaita-icon-theme
)
AUR_PKGS=(
  zen-browser-bin
)

if ask "Update the system and install all packages?"; then
  section "System update"
  sudo pacman -Syu --noconfirm >>"$INSTLOG" 2>&1
  ok "System up to date"

  section "Installing ${#PACMAN_PKGS[@]} official packages"
  sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" >>"$INSTLOG" 2>&1
  ok "Official packages installed"

  section "Installing ${#AUR_PKGS[@]} AUR packages"
  yay -S --needed --noconfirm "${AUR_PKGS[@]}" >>"$INSTLOG" 2>&1
  ok "AUR packages installed"

  if ! rustup show active-toolchain >/dev/null 2>&1; then
    note "Setting up the stable Rust toolchain..."
    rustup default stable >>"$INSTLOG" 2>&1
    ok "rust stable ready"
  fi
fi

# ------------------------------------------------------------
# Zsh: oh-my-zsh, plugins, default shell
# ------------------------------------------------------------
if ask "Set up zsh (oh-my-zsh, plugins, make it your login shell)?"; then
  section "Zsh"
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >>"$INSTLOG" 2>&1
    ok "oh-my-zsh installed"
  else
    ok "oh-my-zsh already installed"
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
      git clone --depth 1 "https://github.com/zsh-users/$plugin" "$ZSH_CUSTOM/plugins/$plugin" >>"$INSTLOG" 2>&1
      ok "$plugin installed"
    else
      ok "$plugin already installed"
    fi
  done

  if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    sudo chsh -s "$(command -v zsh)" "$USER" >>"$INSTLOG" 2>&1
    ok "Login shell changed to zsh (takes effect on next login)"
  else
    ok "zsh is already the login shell"
  fi
fi

# ------------------------------------------------------------
# Tmux plugin manager
# ------------------------------------------------------------
section "Tmux plugins"
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" >>"$INSTLOG" 2>&1
  ok "tpm installed (plugins install on first tmux start, or prefix + I)"
else
  ok "tpm already installed"
fi

# ------------------------------------------------------------
# Config files
# ------------------------------------------------------------
# Backs up anything already at $2, then symlinks (or copies) $1 there.
install_path() {
  local src="$1" dest="$2"
  if [[ "$INSTALL_MODE" == "symlink" && -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    ok "$(basename "$dest") already linked"
    return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/"
    warn "Existing $(basename "$dest") moved to $BACKUP_DIR"
  fi
  if [[ "$INSTALL_MODE" == "symlink" ]]; then
    ln -s "$src" "$dest"
    ok "Linked $dest"
  else
    cp -r "$src" "$dest"
    ok "Copied $dest"
  fi
}

if ask "Install config files ($INSTALL_MODE mode)?"; then
  section "Configs → ~/.config"
  mkdir -p "$HOME/.config"
  for src in "$CONFIG_DIR"/*; do
    install_path "$src" "$HOME/.config/$(basename "$src")"
  done

  section "Home dotfiles → ~"
  for src in "$HOMEFILES_DIR"/.*; do
    [[ -f "$src" ]] || continue
    [[ "$(basename "$src")" == ._* ]] && continue # macOS metadata junk
    install_path "$src" "$HOME/$(basename "$src")"
  done

  # Standard ~/Documents, ~/Downloads, ... directories
  command -v xdg-user-dirs-update >/dev/null && xdg-user-dirs-update && ok "XDG user directories created"

  # Machine-local monitor config (gitignored) — Hyprland sources it and
  # errors if it does not exist.
  if [[ ! -f "$HOME/.config/hypr/monitors.conf" ]]; then
    printf '# Machine-local monitor layout — not tracked by git.\n# See https://wiki.hypr.land/Configuring/Monitors/\nmonitor = ,preferred,auto,1\n' \
      > "$HOME/.config/hypr/monitors.conf"
    ok "Created default hypr/monitors.conf (edit it for your monitor layout)"
  fi
fi

# ------------------------------------------------------------
# System services
# ------------------------------------------------------------
if ask "Enable system services (NetworkManager, bluetooth, sddm)?"; then
  section "Services"
  sudo systemctl enable NetworkManager.service >>"$INSTLOG" 2>&1 && ok "NetworkManager enabled"
  sudo systemctl enable bluetooth.service >>"$INSTLOG" 2>&1 && ok "bluetooth enabled"
  sudo systemctl enable sddm.service >>"$INSTLOG" 2>&1 && ok "sddm enabled"
fi

# ------------------------------------------------------------
# SDDM theme
# ------------------------------------------------------------
if ask "Install the minimal-sddm login theme?"; then
  section "SDDM theme"
  sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d
  sudo rm -rf /usr/share/sddm/themes/minimal-sddm
  sudo cp -r "$DOTFILES_DIR/setup/minimal-sddm" /usr/share/sddm/themes/minimal-sddm
  sudo cp "$DOTFILES_DIR/setup/sddm.conf.d/10-theme.conf" /etc/sddm.conf.d/10-theme.conf
  ok "Theme installed to /usr/share/sddm/themes/minimal-sddm"
fi

echo
echo "============================================"
echo "  ✅ All done!"
echo "============================================"
echo
echo "  Next steps:"
echo "   • Reboot (or 'systemctl start sddm') to log in to Hyprland"
echo "   • Adjust ~/dotfiles/config/hypr/monitors.conf for your displays"
echo "   • First nvim start installs plugins & language servers automatically"
echo "   • In tmux, press ctrl-a + I once to install tmux plugins"
echo
[[ -d "$BACKUP_DIR" ]] && echo "  Your previous configs were backed up to: $BACKUP_DIR"
exit 0
