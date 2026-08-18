# ---- oh-my-zsh -------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # prompt is handled by starship
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

# ---- environment -----------------------------------------------
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export MANPAGER="sh -c 'col -bx | bat -l man -p'"   # colourful man pages
export GOPATH="$HOME/go"
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$GOPATH/bin:$BUN_INSTALL/bin:$PNPM_HOME:$PATH"

# ---- history ---------------------------------------------------
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# ---- aliases ---------------------------------------------------
alias v='nvim'
alias lg='lazygit'
alias ld='lazydocker'
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --git --group-directories-first'
alias la='eza -la --icons --git --group-directories-first'
alias tree='eza --tree --icons'
alias cat='bat --paging=never'
alias grep='rg'
alias update='yay -Syu'
alias dots='cd ~/dotfiles'
alias hyprcfg='nvim ~/.config/hypr/hyprland.lua'
alias hyprlog='hyprctl rollinglog -f'
alias keys='keybinds'          # keybind cheatsheet overlay (SUPER+/); `keys tmux` for tmux

# AI agents
alias cc='claude'
alias ccc='claude --continue'
alias ccr='claude --resume'
alias t3='t3code'

# ---- tools -----------------------------------------------------
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
command -v fzf    >/dev/null && source <(fzf --zsh)
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
eval "$(starship init zsh)"

# bun / pnpm completions when present
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
