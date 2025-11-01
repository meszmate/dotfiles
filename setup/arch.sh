#!/usr/bin/env bash
# ========================================
#  Arch Linux Dotfiles Installer
#  Interactive setup script for your system
# ========================================

set -e

# ----------- CONFIG -----------
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$DOTFILES_DIR/config"
HOMEFILES_DIR="$DOTFILES_DIR/home"
# ------------------------------

COK="[✅ OK]"
CWR="[⚠️ WARN]"
CER="[❌ ERROR]"
CNT="[🔧 NOTE]"

echo "========================================"
echo "        🧩 Arch Linux Setup Tool"
echo "========================================"
echo
echo "Dotfiles directory: $DOTFILES_DIR"
echo

# --- Ensure dotfiles folder exists ---
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "❌ Error: dotfiles directory not found at $DOTFILES_DIR"
  exit 1
fi

# --- Prevent moving or deleting dotfiles folder ---
chmod -R a-w "$DOTFILES_DIR"
echo "🔒 Made $DOTFILES_DIR read-only for safety (no accidental deletes)."
echo


### Package installation ###
read -n1 -rep $'[\e[1;33mACTION\e[0m] - Install core packages now? (y,n): ' INST
echo
if [[ $INST =~ ^[Yy]$ ]]; then
    echo -e "$CNT Updating system and yay database..."
    yay -Suy --noconfirm &>> "$INSTLOG"

    echo -e "\n$CNT Stage 1 - Main components..."
    MAIN_PKGS=(hyprland kitty waybar swww swaylock-effects wofi mako xdg-desktop-portal-hyprland swappy grim slurp thunar)
    for PKG in "${MAIN_PKGS[@]}"; do
        if yay -Qs "$PKG" &>/dev/null; then
            echo -e "$COK $PKG already installed."
        else
            echo -e "$CNT Installing $PKG..."
            yay -S --noconfirm "$PKG" &>> "$INSTLOG"
        fi
    done

    echo -e "\n$CNT Stage 2 - Utilities..."
    UTIL_PKGS=(polkit-gnome python-requests pamixer pavucontrol brightnessctl bluez bluez-utils blueman network-manager-applet gvfs thunar-archive-plugin file-roller btop pacman-contrib pipewire pipewire-pulse neovim nodejs npm unzip rustup erlang elixir fzf zsh starship)
    for PKG in "${UTIL_PKGS[@]}"; do
        if yay -Qs "$PKG" &>/dev/null; then
            echo -e "$COK $PKG already installed."
        else
            echo -e "$CNT Installing $PKG..."
            yay -S --noconfirm "$PKG" &>> "$INSTLOG"
        fi
    done

    echo -e "\n$CNT Stage 3 - Theme & visual tools..."
    THEME_PKGS=(starship ttf-jetbrains-mono-nerd noto-fonts-emoji lxappearance xfce4-settings sddm-git qt5-svg qt5-quickcontrols2 qt5-graphicaleffects)
    for PKG in "${THEME_PKGS[@]}"; do
        if yay -Qs "$PKG" &>/dev/null; then
            echo -e "$COK $PKG already installed."
        else
            echo -e "$CNT Installing $PKG..."
            yay -S --noconfirm "$PKG" &>> "$INSTLOG"
        fi
    done

    rustup default stable &>> "$INSTLOG"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &>> "$INSTLOG"
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

    echo -e "\n$CNT Enabling services..."
    sudo systemctl enable --now bluetooth.service &>> "$INSTLOG"
    sudo systemctl enable sddm &>> "$INSTLOG"
    sudo systemctl --user enable --now pipewire pipewire-pulse &>> "$INSTLOG"

    echo -e "$CNT Cleaning old xdg portals..."
    yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk &>> "$INSTLOG"
fi

# --- Ask user for install mode ---
echo "How do you want to setup dotfiles?"
echo "1) 🔗 Symlink (sync mode) - changes auto-sync with Git repo in this location"
echo "2) 📋 Copy (static mode)  - independent copies of files"
echo "3) Skip"
echo
read -rp "Choose [1/2]: " MODE

if [[ "$MODE" == "1" ]]; then
  INSTALL_MODE="symlink"
  echo "You chose SYMLINK mode."
elif [[ "$MODE" == "2" ]]; then
  INSTALL_MODE="copy"
  echo "You chose COPY mode."
elif [[ "$MODE" == "3" ]]; then
    echo "Skipping config files..."
else
  echo "Invalid option."
  exit 1
fi

echo


if [[ "$MODE" != "3" ]]; then
    # --- Helper functions ---
    link_or_copy() {
      src="$1"
      dest="$2"

      if [ "$INSTALL_MODE" == "symlink" ]; then
        ln -sf "$src" "$dest"
        echo "🔗 Linked: $dest → $src"
      else
        cp -r "$src" "$dest"
        echo "📋 Copied: $src → $dest"
      fi
    }

    # --- Install config folders ---
    echo "==> Installing configs..."

    mkdir -p "$HOME/.config"

    for dir in "$CONFIG_DIR"/*; do
      name=$(basename "$dir")
      target="$HOME/.config/$name"
      link_or_copy "$dir" "$target"
    done

    # --- Install home files (.zshrc, .gitconfig, etc.) ---
    echo "==> Installing home dotfiles..."

    for file in "$HOMEFILES_DIR"/.*; do
      [ -f "$file" ] || continue
      name=$(basename "$file")
      [[ "$name" == "." || "$name" == ".." ]] && continue
      target="$HOME/$name"
      link_or_copy "$file" "$target"
    done
fi

# --- Optional SDDM theme setup ---
if [ -d "$DOTFILES_DIR/setup/minimal-sddm" ]; then
  echo
  read -rp "Install SDDM theme from setup/minimal-sddm ? [y/N]: " INSTALL_SDDM
  if [[ "$INSTALL_SDDM" =~ ^[Yy]$ ]]; then
    echo "==> Setting up SDDM theme and config..."

    sudo mkdir -p /usr/share/sddm/themes
    sudo mkdir -p /etc/sddm.conf.d

    THEME_SRC="$DOTFILES_DIR/setup/minimal-sddm"
    THEME_DEST="/usr/share/sddm/themes/minimal-sddm"

    CONF_SRC="$DOTFILES_DIR/setup/sddm.conf.d/10-theme.conf"
    CONF_DEST="/etc/sddm.conf.d/10-theme.conf"

    # use the same link_or_copy() helper, but with sudo
    if [ "$INSTALL_MODE" == "symlink" ]; then
      sudo ln -sf "$THEME_SRC" "$THEME_DEST"
      echo "🔗 Linked (root): $THEME_DEST → $THEME_SRC"

      if [ -f "$CONF_SRC" ]; then
        sudo ln -sf "$CONF_SRC" "$CONF_DEST"
        echo "🔗 Linked (root): $CONF_DEST → $CONF_SRC"
      else
        echo -e "[Theme]\nCurrent=minimal-sddm" | sudo tee "$CONF_DEST" >/dev/null
      fi

    else
      sudo cp -r "$THEME_SRC" "$THEME_DEST"
      echo "📋 Copied (root): $THEME_SRC → $THEME_DEST"

      if [ -f "$CONF_SRC" ]; then
        sudo cp "$CONF_SRC" "$CONF_DEST"
        echo "📋 Copied (root): $CONF_SRC → $CONF_DEST"
      else
        echo -e "[Theme]\nCurrent=minimal-sddm" | sudo tee "$CONF_DEST" >/dev/null
      fi
    fi

    echo "🎨 SDDM theme 'minimal-sddm' installed."
    echo "🧩 Config placed at: $CONF_DEST"
  fi
fi

echo
echo "✅ Installation complete!"

echo
echo "✨ Enjoy your new Arch setup! You can start hyprland by running the Hyprland command."
