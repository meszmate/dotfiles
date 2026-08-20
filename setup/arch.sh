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
#    --sync       unattended re-run used by dotfiles-sync: pulls in
#                 new packages/configs, skips root-config steps
# ============================================================

set -Eeuo pipefail

REPO_URL="https://github.com/meszmate/dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CONFIG_DIR="$DOTFILES_DIR/config"
HOMEFILES_DIR="$DOTFILES_DIR/home"
BIN_DIR="$DOTFILES_DIR/bin"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
INSTLOG="$HOME/dotfiles-install.log"

ASSUME_YES=0
SYNC_MODE=0
INSTALL_MODE="symlink"
PREFS_FILE="$HOME/.config/dotfiles-prefs"

ok()   { printf '  \e[1;32m✔\e[0m %s\n' "$*"; }
warn() { printf '  \e[1;33m⚠\e[0m %s\n' "$*"; }
err()  { printf '  \e[1;31m✘\e[0m %s\n' "$*" >&2; }
note() { printf '  \e[1;34m➜\e[0m %s\n' "$*"; }

STEP=0
TOTAL_STEPS=10
section() {
  STEP=$((STEP + 1))
  printf '\n\e[1;35m━━━ [%d/%d] %s\e[0m\n' "$STEP" "$TOTAL_STEPS" "$*"
}

trap 'err "Setup failed at line $LINENO. Details: $INSTLOG"' ERR

usage() { sed -n '2,19p' "$0"; exit 0; }

for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    --sync)   SYNC_MODE=1; ASSUME_YES=1 ;;
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

if [[ $SYNC_MODE -eq 0 ]]; then
  note "Asking for sudo up front (kept alive for the whole run)..."
  sudo -v
  ( while sudo -n true 2>/dev/null; do sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
fi

# ------------------------------------------------------------
# Preferences — everything is asked here, then the setup runs
# on its own showing progress. Enter always picks the default.
# ------------------------------------------------------------
P_PKGS=0 P_DEV=0 P_AI=0 P_BT=0 P_BROWSER=0 P_ZSH=0 P_CONFIGS=0 P_SVC=0 P_SDDM=0 P_AUTOSYNC=0

if [[ $SYNC_MODE -eq 1 ]]; then
  # Reuse the answers from the original install; default to everything.
  P_PKGS=1 P_DEV=1 P_AI=1 P_BT=1 P_BROWSER=1 P_ZSH=1 P_CONFIGS=1
  # shellcheck source=/dev/null
  [[ -f "$PREFS_FILE" ]] && source "$PREFS_FILE"
  P_SVC=0 P_SDDM=0 P_AUTOSYNC=0 # root-config steps are skipped in sync runs
else
  printf '\n\e[1;36mA few questions first — then everything runs on its own:\e[0m\n\n'
  if [[ $ASSUME_YES -eq 0 && "$INSTALL_MODE" == "symlink" ]]; then
    read -rp "$(printf '  \e[1;33m?\e[0m Symlink configs (live-sync with repo, recommended) or copy? [S/c] ')" mode_answer
    [[ $mode_answer =~ ^[Cc] ]] && INSTALL_MODE="copy"
  fi
  if ask "Install the desktop & all packages (Hyprland, audio, fonts, tools)?"; then P_PKGS=1; fi
  if ask "  + development toolchain (Node/Bun/pnpm, Python/uv, Rust, Go, Java, Elixir, C/C++, Zig, Docker)?"; then P_DEV=1; fi
  if ask "  + AI coding tools (Claude Code, T3 Code, GitHub CLI, desktop notifications for agents)?"; then P_AI=1; fi
  if ask "  + bluetooth support (bluez, blueman)?"; then P_BT=1; fi
  if ask "  + zen browser (AUR)?"; then P_BROWSER=1; fi
  if ask "Set up zsh (oh-my-zsh, plugins, login shell)?"; then P_ZSH=1; fi
  if ask "Install config files ($INSTALL_MODE mode)?"; then P_CONFIGS=1; fi
  if ask "Enable system services (NetworkManager, sddm, bluetooth, power-profiles, docker)?"; then P_SVC=1; fi
  if ask "Install the minimal-sddm login theme (same wallpaper as the lock screen)?"; then P_SDDM=1; fi
  if ask "Enable automatic sync (timer pulls repo & installs new packages)?"; then P_AUTOSYNC=1; fi
  printf '\n  \e[1;36mAll set — running the full setup now.\e[0m\n'

  # Remember the answers so `dotfiles-sync` applies the same selection.
  mkdir -p "$(dirname "$PREFS_FILE")"
  cat > "$PREFS_FILE" <<EOP
INSTALL_MODE=$INSTALL_MODE
P_PKGS=$P_PKGS
P_DEV=$P_DEV
P_AI=$P_AI
P_BT=$P_BT
P_BROWSER=$P_BROWSER
P_ZSH=$P_ZSH
P_CONFIGS=$P_CONFIGS
EOP
fi

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
  # Hyprland + first-party ecosystem
  hyprland hyprlock hypridle hyprpaper hyprpicker hyprsunset hyprshutdown hyprpolkitagent
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland
  # Desktop shell: bar, launcher, notifications, OSD
  waybar rofi rofi-calc rofi-emoji swaync swayosd libnotify
  # Keybind cheatsheet overlay (bin/keybinds: GTK4 + layer-shell)
  gtk4 gtk4-layer-shell python-gobject
  # Screenshots, recording, clipboard
  grim slurp swappy wf-recorder wl-clipboard cliphist wl-clip-persist
  # Terminal, shell & CLI tools
  kitty zsh starship tmux fzf zoxide eza bat fd ripgrep jq lazygit btop
  man-db unzip wget
  # Neovim + what nvim-treesitter (main) needs to build parsers (gcc comes with base-devel)
  neovim tree-sitter-cli
  # System / repo info at a glance (config/fastfetch; onefetch = fastfetch for git repos)
  fastfetch onefetch
  # Audio
  pipewire pipewire-alsa pipewire-pulse wireplumber pamixer pavucontrol playerctl
  # Network
  networkmanager network-manager-applet
  # Files
  thunar thunar-archive-plugin thunar-volman tumbler file-roller gvfs
  # System utilities
  brightnessctl power-profiles-daemon pacman-contrib xdg-user-dirs
  # Fonts
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji inter-font
  # Login manager (theme needs the qt6 modules)
  sddm qt6-svg qt6-5compat qt6-declarative
  # GTK / Qt theming
  nwg-look adw-gtk-theme papirus-icon-theme adwaita-icon-theme qt6ct qt5ct
)
DEV_PKGS=(
  # JavaScript / TypeScript
  nodejs npm pnpm bun
  # Python
  python uv ruff
  # Rust, Go, Java, Elixir
  rustup go jdk-openjdk erlang elixir
  # C / C++ / Zig
  clang cmake zig
  # Lua (also used by the Hyprland config; lua-language-server for editor completion)
  lua luarocks lua-language-server stylua
  # Containers (docker 29 has no legacy builder: `docker build` needs buildx;
  # docker-compose provides the `docker compose` plugin) & git tooling
  docker docker-compose docker-buildx lazydocker git-delta direnv
  # Shell / misc language tooling
  shellcheck shfmt
)
AI_PKGS=(github-cli)
AI_AUR_PKGS=(t3code-bin)
BT_PKGS=(bluez bluez-utils blueman)
BROWSER_AUR_PKGS=(zen-browser-bin)

section "System update & packages"
if [[ $P_PKGS -eq 1 ]]; then
  PKGS=("${CORE_PKGS[@]}")
  [[ $P_DEV -eq 1 ]] && PKGS+=("${DEV_PKGS[@]}")
  [[ $P_AI -eq 1 ]]  && PKGS+=("${AI_PKGS[@]}")
  [[ $P_BT -eq 1 ]]  && PKGS+=("${BT_PKGS[@]}")

  note "Updating the system (pacman output shown live)..."
  sudo pacman -Syu --noconfirm
  ok "System up to date"

  note "Installing ${#PKGS[@]} official packages..."
  sudo pacman -S --needed --noconfirm "${PKGS[@]}"
  ok "Official packages installed"

  AUR=()
  [[ $P_BROWSER -eq 1 ]] && AUR+=("${BROWSER_AUR_PKGS[@]}")
  [[ $P_AI -eq 1 ]] && AUR+=("${AI_AUR_PKGS[@]}")
  if [[ ${#AUR[@]} -gt 0 ]]; then
    note "Installing ${#AUR[@]} AUR package(s): ${AUR[*]}"
    yay -S --needed --noconfirm "${AUR[@]}"
    ok "AUR packages installed"
  fi

  if [[ $P_DEV -eq 1 ]] && ! rustup show active-toolchain >/dev/null 2>&1; then
    note "Setting up the stable Rust toolchain..."
    rustup default stable >>"$INSTLOG" 2>&1
    ok "rust stable ready"
  fi

  # Salesforce CLI (sf.nvim + the Apex LSP in Neovim use it) — npm package, so it
  # goes through pnpm's global dir (~/.local/share/pnpm/bin, on PATH via .zshrc)
  if [[ $P_DEV -eq 1 ]] && ! command -v sf >/dev/null 2>&1; then
    note "Installing the Salesforce CLI (@salesforce/cli via pnpm)..."
    if PNPM_HOME="$HOME/.local/share/pnpm" PATH="$HOME/.local/share/pnpm/bin:$HOME/.local/share/pnpm:$PATH" \
       pnpm add -g @salesforce/cli >>"$INSTLOG" 2>&1; then
      ok "sf CLI installed"
    else
      warn "Salesforce CLI install failed (see $INSTLOG) — pnpm add -g @salesforce/cli"
    fi
  fi
else
  warn "Skipped package installation"
fi

# ------------------------------------------------------------
# AI coding tools: Claude Code (+ hooks), Codex CLI, T3 Code
# ------------------------------------------------------------
section "AI coding tools"
if [[ $P_AI -eq 1 ]]; then
  if command -v claude >/dev/null || [[ -x "$HOME/.local/bin/claude" ]]; then
    ok "Claude Code already installed"
  else
    note "Installing Claude Code (official installer → ~/.local/bin/claude)..."
    if curl -fsSL https://claude.ai/install.sh | bash >>"$INSTLOG" 2>&1; then
      ok "Claude Code installed — run 'claude' once to log in"
    else
      warn "Claude Code installer failed (see $INSTLOG); install later with: curl -fsSL https://claude.ai/install.sh | bash"
    fi
  fi
  # Codex CLI — the official installer, not extra/openai-codex: the repo package
  # trails upstream (0.147 vs 0.148 at the time of writing). Installs a
  # standalone build into ~/.codex and symlinks ~/.local/bin/codex; it only
  # edits a shell profile when ~/.local/bin is off PATH, which .zshrc rules out
  # (it must never rewrite ~/.zshrc — that is a symlink into this repo).
  if command -v codex >/dev/null || [[ -x "$HOME/.local/bin/codex" ]]; then
    ok "Codex CLI already installed ($("$HOME/.local/bin/codex" --version 2>/dev/null || echo unknown))"
  else
    note "Installing Codex CLI (official installer → ~/.local/bin/codex)..."
    if CODEX_NON_INTERACTIVE=1 PATH="$HOME/.local/bin:$PATH" \
       sh -c 'curl -fsSL https://chatgpt.com/codex/install.sh | sh' >>"$INSTLOG" 2>&1; then
      ok "Codex CLI installed — run 'codex' once to log in"
    else
      warn "Codex installer failed (see $INSTLOG); install later with: curl -fsSL https://chatgpt.com/codex/install.sh | sh"
    fi
  fi
  command -v t3code >/dev/null && ok "T3 Code installed (t3code — drives claude/codex/opencode CLIs)"
  # Notification hooks (bin/claude-notify) + no Claude branding in commits/PRs
  if command -v jq >/dev/null; then
    "$DOTFILES_DIR/setup/claude-hooks-install" >>"$INSTLOG" 2>&1 && ok "Claude Code configured (notify hooks, no co-author trailer)"
  fi
else
  warn "Skipped AI tools"
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

# Convert a legacy hyprlang `monitor = NAME,MODE,POS,SCALE` line into Lua.
monitors_conf_to_lua() {
  awk -F'[=,]' '
    /^[[:space:]]*monitor[[:space:]]*=/ {
      for (i = 2; i <= NF; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i)
      out = $2; mode = (NF >= 3 ? $3 : "preferred"); pos = (NF >= 4 ? $4 : "auto"); scale = (NF >= 5 ? $5 : "auto")
      if (scale ~ /^[0-9.]+$/) sc = scale; else sc = "\"" scale "\""
      printf "hl.monitor({ output = \"%s\", mode = \"%s\", position = \"%s\", scale = %s })\n", out, mode, pos, sc
    }' "$1"
}

section "Config files ($INSTALL_MODE mode)"
if [[ $P_CONFIGS -eq 1 ]]; then
  note "Configs → ~/.config"
  mkdir -p "$HOME/.config"
  for src in "$CONFIG_DIR"/*; do
    [[ -e "$src" ]] || continue
    install_path "$src" "$HOME/.config/$(basename "$src")"
  done

  # Symlinks in ~/.config that point into the repo but whose target vanished
  # (configs removed from the repo, e.g. wofi/mako → rofi/swaync)
  for link in "$HOME/.config"/*; do
    if [[ -L "$link" && ! -e "$link" && "$(readlink "$link")" == "$CONFIG_DIR"/* ]]; then
      rm -f "$link" && warn "Removed dangling link $(basename "$link") (config no longer in repo)"
    fi
  done

  note "Home dotfiles → ~"
  for src in "$HOMEFILES_DIR"/.*; do
    [[ -f "$src" ]] || continue
    [[ "$(basename "$src")" == ._* ]] && continue # macOS metadata junk
    install_path "$src" "$HOME/$(basename "$src")"
  done

  note "Scripts → ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  for src in "$BIN_DIR"/*; do
    [[ -f "$src" ]] || continue
    ln -sfn "$src" "$HOME/.local/bin/$(basename "$src")"
  done
  ok "bin/* linked into ~/.local/bin"

  # Standard ~/Documents, ~/Downloads, ... directories
  command -v xdg-user-dirs-update >/dev/null && xdg-user-dirs-update && ok "XDG user directories created"

  # Machine-local monitor layout (gitignored). Hyprland uses the Lua config;
  # a legacy monitors.conf from an older install is converted automatically.
  HYPR="$HOME/.config/hypr"
  if [[ ! -f "$HYPR/monitors.lua" ]]; then
    {
      printf -- '-- Machine-local monitor layout — not tracked by git.\n'
      printf -- '-- Docs: https://wiki.hypr.land/Configuring/Basics/Monitors/   (hyprctl monitors all)\n'
      if [[ -f "$HYPR/monitors.conf" ]] && grep -qE '^[[:space:]]*monitor[[:space:]]*=' "$HYPR/monitors.conf"; then
        monitors_conf_to_lua "$HYPR/monitors.conf"
      else
        printf 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })\n'
      fi
    } > "$HYPR/monitors.lua"
    ok "Created hypr/monitors.lua (edit it for your monitor layout)"
  fi
  [[ -f "$HYPR/monitors.conf" ]] && rm -f "$HYPR/monitors.conf" && ok "Removed legacy hypr/monitors.conf (converted to monitors.lua)"

  # Wallpaper symlink used by hyprpaper + hyprlock (the picker repoints it)
  [[ -e "$HYPR/wallpaper.current" ]] || ln -s wallpaper.jpg "$HYPR/wallpaper.current"

  # qt6ct/qt5ct store the palette path absolutely → generate from templates
  for q in qt6ct qt5ct; do
    if [[ -f "$HOME/.config/$q/$q.conf.in" ]]; then
      sed "s|@HOME@|$HOME|g" "$HOME/.config/$q/$q.conf.in" > "$HOME/.config/$q/$q.conf"
    fi
  done
  ok "Qt theme configs generated"
else
  warn "Skipped config files"
fi

# ------------------------------------------------------------
# Tmux plugins (needs ~/.config/tmux linked above)
# ------------------------------------------------------------
section "Tmux plugins"
# tpm + every @plugin from config/tmux/tmux.conf + the tmux-thumbs binary,
# headless, so the styled status bar works on the very first `tmux`
# (tmux.conf runs the same script itself if anything is missing).
if [[ -x "$HOME/.config/tmux/scripts/bootstrap" ]] && "$HOME/.config/tmux/scripts/bootstrap" >>"$INSTLOG" 2>&1; then
  ok "tmux plugins installed"
else
  warn "tmux plugin bootstrap failed (see $INSTLOG) — run ~/.config/tmux/scripts/bootstrap later"
fi

# ------------------------------------------------------------
# System services
# ------------------------------------------------------------
section "System services"
if [[ $P_SVC -eq 1 ]]; then
  sudo systemctl enable NetworkManager.service >>"$INSTLOG" 2>&1 && ok "NetworkManager enabled"
  # archinstall often leaves iwd/systemd-networkd/wpa_supplicant enabled next to
  # NetworkManager → two managers fight over Wi-Fi. Make NM the only one.
  "$DOTFILES_DIR/setup/fix-network" >>"$INSTLOG" 2>&1 && ok "NetworkManager is the single network manager (iwd backend if iwd is present)"
  [[ $P_BT -eq 1 ]] && sudo systemctl enable bluetooth.service >>"$INSTLOG" 2>&1 && ok "bluetooth enabled"
  sudo systemctl enable sddm.service >>"$INSTLOG" 2>&1 && ok "sddm enabled"
  sudo systemctl enable --now power-profiles-daemon.service >>"$INSTLOG" 2>&1 && ok "power-profiles-daemon enabled (waybar power profile switcher)"
  if [[ $P_DEV -eq 1 ]] && command -v docker >/dev/null; then
    # socket-activated: the daemon starts on the first `docker …` and stays off otherwise
    sudo systemctl enable --now docker.socket >>"$INSTLOG" 2>&1 && ok "docker enabled (socket-activated, ready now)"
    if ! id -nG "$USER" | grep -qw docker; then
      sudo usermod -aG docker "$USER" && ok "Added $USER to the docker group (takes effect at the next login; \`newgrp docker\` for this shell)"
    fi
  fi
else
  warn "Skipped services"
fi

# ------------------------------------------------------------
# SDDM theme
# ------------------------------------------------------------
section "SDDM login theme"
if [[ $P_SDDM -eq 1 ]]; then
  # Same wallpaper on the login screen as on the desktop / lock screen
  INSTALL_MODE="$INSTALL_MODE" "$DOTFILES_DIR/setup/install-sddm-theme" >>"$INSTLOG" 2>&1
  if [[ "$INSTALL_MODE" == "symlink" ]]; then ok "Theme linked from setup/minimal-sddm (edits go live at the next login)"; else ok "Theme copied to /usr/share/sddm/themes/minimal-sddm (re-run setup/install-sddm-theme after editing it)"; fi
else
  warn "Skipped SDDM theme"
fi

# ------------------------------------------------------------
# Automatic sync (systemd user timer)
# ------------------------------------------------------------
section "Automatic sync"
if [[ $P_AUTOSYNC -eq 1 ]]; then
  mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"
  ln -sf "$DOTFILES_DIR/setup/dotfiles-sync" "$HOME/.local/bin/dotfiles-sync"
  cp "$DOTFILES_DIR/setup/systemd/dotfiles-sync.service" \
     "$DOTFILES_DIR/setup/systemd/dotfiles-sync.timer" \
     "$HOME/.config/systemd/user/"
  ok "dotfiles-sync command and timer units installed"

  # The timer runs without a terminal, so pacman needs passwordless sudo.
  printf '%s ALL=(ALL) NOPASSWD: /usr/bin/pacman\n' "$USER" | sudo tee /etc/sudoers.d/11-dotfiles-sync >/dev/null
  sudo chmod 440 /etc/sudoers.d/11-dotfiles-sync
  if sudo visudo -cf /etc/sudoers.d/11-dotfiles-sync >/dev/null; then
    ok "Passwordless pacman for $USER (only pacman — /etc/sudoers.d/11-dotfiles-sync)"
  else
    sudo rm -f /etc/sudoers.d/11-dotfiles-sync
    err "sudoers validation failed — auto-sync will need a manual 'dotfiles-sync' run"
  fi

  systemctl --user daemon-reload >>"$INSTLOG" 2>&1 || true
  if systemctl --user enable dotfiles-sync.timer >>"$INSTLOG" 2>&1; then
    ok "Timer enabled: 3 min after boot, then every 6 h (run 'dotfiles-sync' anytime)"
  else
    warn "Could not enable the user timer now — run: systemctl --user enable --now dotfiles-sync.timer"
  fi
elif [[ $SYNC_MODE -eq 1 ]]; then
  ok "Sync run complete"
else
  warn "Skipped automatic sync"
fi

echo
echo "============================================"
echo "  ✅ All done!"
echo "============================================"
if [[ $SYNC_MODE -eq 0 ]]; then
  echo
  echo "  Next steps:"
  echo "   • Reboot (or 'systemctl start sddm') to log in to Hyprland"
  echo "   • SUPER+/ shows every keybind; SUPER+Space is the launcher"
  echo "   • Adjust ~/.config/hypr/monitors.lua for your displays"
  echo "   • First nvim start installs plugins & language servers automatically"
  [[ $P_AI -eq 1 ]] && echo "   • Run 'claude' once to log in; T3 Code is in the launcher"
  echo
  [[ -d "$BACKUP_DIR" ]] && echo "  Your previous configs were backed up to: $BACKUP_DIR"
fi
exit 0
