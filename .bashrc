# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#Alias
alias grep='grep --color=auto'
alias cat='bat'
alias ls='lsd'
alias ll='lsd -l'
alias ..='cd ..'
alias ...='cd ../..'
alias r='source ~/.bashrc'

#Prompt
PS1='\[\e[1;38;5;218m\]\u\[\e[0m\] \[\e[38;5;15m\]\W ❯ \[\e[0m\]'

# Historial
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
