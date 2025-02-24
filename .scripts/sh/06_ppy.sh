# shellcheck shell=bash

function prj() {
  if [[ $# -eq 0 ]]; then
    local dest="${PGITDIR}"
  else
    local dest="${PGITDIR}/$1"
  fi
  cd "$dest" || echo "No directory: $dest"
}

function ppj() { prj "$1/python"; }

function get_pyvenv_manager() {
  if command -v pyenv &>/dev/null; then
    echo "pyenv"
  else
    echo "/usr/bin/python3"
  fi
}

function mkpyenv() {
  if [[ "$(get_pyvenv_manager)" == "pyenv" ]]; then
    if [[ "$#" -eq 1 ]]; then
      pyenv virtualenv system "$1"
    elif [[ "$#" -eq 2 ]]; then
      pyenv virtualenv "$1" "$2"
    else
      echo "Invalid arguments provided"
    fi
  else
    /usr/bin/python3 -m venv "${HOME}/.venvs/$1"
  fi
}

function get_venv_dir() {
  if [[ "$(get_pyvenv_manager)" == "pyenv" ]]; then
    echo "${HOME}/.pyenv/versions"
  else
    mkdir -pv "${HOME}/.venvs/"
    echo "${HOME}/.venvs/"
  fi
}

function workon() {
  if [[ "$(get_pyvenv_manager)" == "pyenv" ]]; then
    pyenv activate "$1"
  else
    source "${HOME}/.venvs/$1/bin/activate"
  fi
  echo "$1 activated!"
}

function ls_pyenv() {
  if [[ "$(get_pyvenv_manager)" == "pyenv" ]]; then
    pyenv versions
  else
    ls "${HOME}/.venvs/"
  fi
}

function plist() { python -m pip list "$@"; }
function jlab() { python -m jupyter lab; }
function jcons() { python -m jupyter console; }
function pins() { python -m pip install "$@"; }
function pinsu() { python -m pip install -U "$@"; }

function fmtjson() {
  /usr/bin/python3 -m json.tool "$1" "$1" --sort-keys --no-ensure-ascii --indent 2
}

function ruffit() { ruff check --fix $1 && ruff format "$@"; }
