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

STEP=0
TOTAL_STEPS=8
section() {
  STEP=$((STEP + 1))
  printf '\n\e[1;35m━━━ [%d/%d] %s\e[0m\n' "$STEP" "$TOTAL_STEPS" "$*"
}

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
  if [[ $ASSUME_YES -eq 1 ]]; then
    printf '  \e[1;33m?\e[0m %s — yes (auto)\n' "$1"
    return 0
  fi
  local answer=""
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
# Preferences — everything is asked here, then the setup runs
# on its own showing progress. Enter always picks the default.
# ------------------------------------------------------------
P_PKGS=0 P_DEV=0 P_BT=0 P_BROWSER=0 P_ZSH=0 P_CONFIGS=0 P_SVC=0 P_SDDM=0

printf '\n\e[1;36mA few questions first — then everything runs on its own:\e[0m\n\n'
if [[ $ASSUME_YES -eq 0 && "$INSTALL_MODE" == "symlink" ]]; then
  read -rp "$(printf '  \e[1;33m?\e[0m Symlink configs (live-sync with repo, recommended) or copy? [S/c] ')" mode_answer
  [[ $mode_answer =~ ^[Cc] ]] && INSTALL_MODE="copy"
fi
if ask "Install the desktop & all packages (Hyprland, audio, fonts, tools)?"; then P_PKGS=1; fi
if ask "  + development toolchain (Node, Rust, Go, Java, Erlang/Elixir)?"; then P_DEV=1; fi
if ask "  + bluetooth support (bluez, blueman)?"; then P_BT=1; fi
if ask "  + zen browser (AUR)?"; then P_BROWSER=1; fi
if ask "Set up zsh (oh-my-zsh, plugins, login shell)?"; then P_ZSH=1; fi
if ask "Install config files ($INSTALL_MODE mode)?"; then P_CONFIGS=1; fi
if ask "Enable system services (NetworkManager, sddm, bluetooth)?"; then P_SVC=1; fi
if ask "Install the minimal-sddm login theme?"; then P_SDDM=1; fi
printf '\n  \e[1;36mAll set — running the full setup now.\e[0m\n'

# ------------------------------------------------------------
# Base tools + clone the repo itself if missing
# ------------------------------------------------------------
section "Base tools & dotfiles repository"
note "Installing base-devel and git..."
sudo pacman -Sy --needed --noconfirm base-devel git >>"$INSTLOG" 2>&1
ok "base-devel and git present"

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  note "Cloning dotfiles to $DOTFILES_DIR..."
  git clone --recurse-submodules "$REPO_URL" "$DOTFILES_DIR" >>"$INSTLOG" 2>&1
  ok "Repository cloned"
else
  ok "Repository already present at $DOTFILES_DIR"
fi
git -C "$DOTFILES_DIR" submodule update --init >>"$INSTLOG" 2>&1 || warn "Could not update the nvim submodule (check network)."

# ------------------------------------------------------------
# AUR helper (yay)
# ------------------------------------------------------------
section "AUR helper (yay)"
if command -v yay >/dev/null; then
  ok "yay already installed"
else
  note "Building yay-bin from the AUR (output shown live)..."
  YAY_TMP=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$YAY_TMP" >>"$INSTLOG" 2>&1
  ( cd "$YAY_TMP" && makepkg -si --noconfirm )
  rm -rf "$YAY_TMP"
  ok "yay installed"
fi

# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------
CORE_PKGS=(
  # Hyprland desktop
  hyprland hyprlock hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  qt5-wayland qt6-wayland polkit-gnome
  waybar wofi mako libnotify hyprpaper grim slurp swappy wl-clipboard cliphist
  # Terminal, shell & CLI tools
  kitty zsh starship tmux fzf zoxide eza bat fd ripgrep lazygit btop
  man-db unzip wget neovim
  # Audio
  pipewire pipewire-alsa pipewire-pulse wireplumber pamixer pavucontrol playerctl
  # Network
  networkmanager network-manager-applet
  # Files
  thunar thunar-archive-plugin file-roller gvfs
  # System utilities
  brightnessctl pacman-contrib python-requests xdg-user-dirs
  # Fonts
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji inter-font
  # Login manager (theme needs the qt6 modules)
  sddm qt6-svg qt6-5compat qt6-declarative
  # GTK theming
  nwg-look adw-gtk-theme papirus-icon-theme adwaita-icon-theme
)
DEV_PKGS=(nodejs npm rustup go jdk-openjdk erlang elixir)
BT_PKGS=(bluez bluez-utils blueman)
AUR_PKGS=(zen-browser-bin)

section "System update & packages"
if [[ $P_PKGS -eq 1 ]]; then
  PKGS=("${CORE_PKGS[@]}")
  [[ $P_DEV -eq 1 ]] && PKGS+=("${DEV_PKGS[@]}")
  [[ $P_BT -eq 1 ]] && PKGS+=("${BT_PKGS[@]}")

  note "Updating the system (pacman output shown live)..."
  sudo pacman -Syu --noconfirm
  ok "System up to date"

  note "Installing ${#PKGS[@]} official packages..."
  sudo pacman -S --needed --noconfirm "${PKGS[@]}"
  ok "Official packages installed"

  if [[ $P_BROWSER -eq 1 ]]; then
    note "Installing ${#AUR_PKGS[@]} AUR package(s)..."
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
    ok "AUR packages installed"
  fi

  if [[ $P_DEV -eq 1 ]] && ! rustup show active-toolchain >/dev/null 2>&1; then
    note "Setting up the stable Rust toolchain..."
    rustup default stable >>"$INSTLOG" 2>&1
    ok "rust stable ready"
  fi
else
  warn "Skipped package installation"
fi

# ------------------------------------------------------------
# Zsh: oh-my-zsh, plugins, default shell
# ------------------------------------------------------------
section "Zsh & shell"
if [[ $P_ZSH -eq 1 ]]; then
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
else
  warn "Skipped zsh setup"
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

section "Config files ($INSTALL_MODE mode)"
if [[ $P_CONFIGS -eq 1 ]]; then
  note "Configs → ~/.config"
  mkdir -p "$HOME/.config"
  for src in "$CONFIG_DIR"/*; do
    install_path "$src" "$HOME/.config/$(basename "$src")"
  done

  note "Home dotfiles → ~"
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
else
  warn "Skipped config files"
fi

# ------------------------------------------------------------
# System services
# ------------------------------------------------------------
section "System services"
if [[ $P_SVC -eq 1 ]]; then
  sudo systemctl enable NetworkManager.service >>"$INSTLOG" 2>&1 && ok "NetworkManager enabled"
  [[ $P_BT -eq 1 ]] && sudo systemctl enable bluetooth.service >>"$INSTLOG" 2>&1 && ok "bluetooth enabled"
  sudo systemctl enable sddm.service >>"$INSTLOG" 2>&1 && ok "sddm enabled"
else
  warn "Skipped services"
fi

# ------------------------------------------------------------
# SDDM theme
# ------------------------------------------------------------
section "SDDM login theme"
if [[ $P_SDDM -eq 1 ]]; then
  sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d
  sudo rm -rf /usr/share/sddm/themes/minimal-sddm
  sudo cp -r "$DOTFILES_DIR/setup/minimal-sddm" /usr/share/sddm/themes/minimal-sddm
  sudo cp "$DOTFILES_DIR/setup/sddm.conf.d/10-theme.conf" /etc/sddm.conf.d/10-theme.conf
  ok "Theme installed to /usr/share/sddm/themes/minimal-sddm"
else
  warn "Skipped SDDM theme"
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
