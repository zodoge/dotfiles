#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

source "$HOME/.zshenv"
source "$HOME/.scripts/sh/base.sh"
source_files "$HOME/.scripts/sh/common/" "sh"
