# shellcheck shell=bash
function d() {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n 10
  fi
}

case "$(ps -p$$ -ocommand)" in
*zsh*)
  setopt auto_cd
  setopt auto_pushd
  setopt pushd_ignore_dups
  setopt pushdminus

  compdef _dirs d
  # alias -g ..='..'
  alias -g ...='../..'
  alias -g ....='../../..'
  alias -g .....='../../../..'
  alias -g ......='../../../../..'

  alias -- -='cd -'
  alias 1='cd -1'
  alias 2='cd -2'
  alias 3='cd -3'
  alias 4='cd -4'
  alias 5='cd -5'
  alias 6='cd -6'
  alias 7='cd -7'
  alias 8='cd -8'
  alias 9='cd -9'

  ;;
*bash*)
  alias ..='cd ..'         # Go up one directory
  alias cd..='cd ..'       # Common misspelling for going up one directory
  alias ...='cd ../..'     # Go up two directories
  alias ....='cd ../../..' # Go up three directories
  alias -- -='cd -'        # Go back

  # Shell History
  alias h='history'
  ;;
*)
  echo ""
  ;;
esac

alias md='mkdir -p'
alias rd='rmdir'

function take { mkdir -pv "$1" && cd "$1" || exit; }

function catt() {
  for i in "$@"; do
    if [[ -d "$i" ]]; then
      ls "$i"
    else
      cat "$i"
    fi
  done
}
alias q='exit'
alias c='clear'
alias cls='clear'

# List directory contents
alias lsa='ls -lah'
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -lAh'

if command -v exa &>/dev/null; then
  alias ls='exa'
  alias sl='ls'
  alias l='exa -lbF --git'
  alias llm='exa -lbGd --git --sort=modified'
  alias la='exa -lbhHigUmuSa --time-style=long-iso --git --color-scale'
  alias lx='exa -lbhHigUmuSa@ --time-style=long-iso --git --color-scale'
  alias lS='exa -1'
  alias lt='exa --tree --level=2'
  alias ll='exa -lbGF --git'
  alias lr='ll -R'
  alias lm='la | "$PAGER"'
  alias lk='ll --sort=size -r'
  alias lc='ll --sort=modified -rm'
  alias lu='ll --sort=modified -ru'
  alias lxx='ll --sort=Extension'
fi
