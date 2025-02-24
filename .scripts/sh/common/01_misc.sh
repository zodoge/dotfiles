if command -v bat &> /dev/null; then
  alias bathelp='bat --plain --language=help'
  help() {
    "$@" --help 2>&1 | bathelp
  }
fi

if command -v nvim &> /dev/null; then
  alias vim='nvim'
fi

if command -v yt-dlp &> /dev/null; then
  alias ytd='yt-dlp'
  alias u23='yt-dlp -x --audio-format mp3'
fi
