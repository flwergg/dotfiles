# If not running interactively, don't do anything
[[ -o interactive ]] || return

# ─────────── Aliases ───────────
alias grep='grep --color=auto'
alias cat='bat'
alias ls='lsd'
alias ll='lsd -l'
alias ..='cd ..'
alias ...='cd ../..'
alias r='source ~/.zshrc'
alias clean-packages='sudo pacman -Rns $(pacman -Qdtq)'
alias clean-pacman='sudo paccache -rk1 && sudo paccache -ruk0 && yay -Sc --noconfirm && flatpak uninstall --unused -y'
alias update-all='yay -Syu && flatpak update'

# ─────────── Prompt ───────────
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%F{225}%b%f '
setopt PROMPT_SUBST

PROMPT='%B%F{218}%n%b%f %F{15}%1~ ${vcs_info_msg_0_}❯ %f'

# ─────────── Historial ───────────
HISTSIZE=10000
SAVEHIST=20000
HISTFILE=~/.zsh_history

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
# setopt HIST_IGNORE_ALL_DUPS  # comentado para analizar frecuencia, descomentar después
setopt HIST_FIND_NO_DUPS

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

eval "$(zoxide init zsh)"
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

fastfetch() {
    local imgs=(~/.config/fastfetch/images/*.png)
    command fastfetch --logo "${imgs[$((RANDOM % ${#imgs[@]} + 1))]}"
}

# Created by `pipx` on 2026-02-20 15:43:10
export PATH="$PATH:/home/gaby/.local/bin"
