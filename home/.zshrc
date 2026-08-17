# ---- oh-my-zsh -------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # prompt is handled by starship
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

# ---- environment -----------------------------------------------
export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ---- history ---------------------------------------------------
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY

# ---- aliases ---------------------------------------------------
alias v='nvim'
alias lg='lazygit'
alias ls='eza --icons'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias tree='eza --tree --icons'
alias cat='bat --paging=never'
alias grep='rg'
alias update='yay -Syu'

# ---- tools -----------------------------------------------------
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
command -v fzf >/dev/null && source <(fzf --zsh)
eval "$(starship init zsh)"
