#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '


find_files() {
  # "$1" => directory, "$2" => extension of files to source
  find -L "$1" -type f -name "*.$2" | while read -r file; do
    echo "$file"
  done
}

source_files() {
  # "$1" => directory, "$2" => extension of files to source
  find -L "$1" -type f -name "*.$2" | while read -r file; do
    source "$file"
  done
}
