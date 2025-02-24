typeset -U PATH path


export XDG_DATA_HOME="$HOME/.config"

# Display timestamps for each command
export HIST_STAMPS="%T %d.%m.%y"
export HISTSIZE=10000
export HISTFILE="$HOME/.zsh_history"
export SAVEHIST=$HISTSIZE
export HISTDUP=erase
# Ignore these commands in history
export HISTORY_IGNORE="(ls|pwd|cd)*"

export PLUGDIR="$HOME/.zsh"

if [[ -d "$HOME/projects/perso" ]]; then
  export PGITDIR="$HOME/projects/perso"
fi

if [[ -d "$HOME/projects/work" ]]; then
  export WGITDIR="$HOME/projects/work"
fi

if [[ -d "$HOME/projects/sublime-text" ]]; then
  export SUBL_DIR="$HOME/projects/sublime-text"
fi

if [[ -f "$HOME/.env/penv" ]]; then
  source "$HOME/.env/penv"
fi

if [[ -f "$HOME/.env/wenv" ]]; then
  source "$HOME/.env/wenv"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
  export PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

if [ -d "$HOME/.cache/scalacli/local-repo/bin/scala-cli" ]; then
  export PATH="$HOME/.cache/scalacli/local-repo/bin/scala-cli:$PATH"
elif [ -d "$HOME/.local/share/coursier/bin" ]; then
  export PATH="$HOME/.local/share/coursier/bin:$PATH"
fi

export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ("$SHLVL" -eq 1 && ! -o LOGIN) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
