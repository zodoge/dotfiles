# shellcheck shell=bash

function _gitlab_projects() {
  case "$1" in
  web | webapp | wa) echo webapp7261752 ;;
  rust | r) echo rust3703601 ;;
  *) echo "invalid project" ;;
  esac
}

function glcl() {
  dd=$(_gitlab_projects "$1")
  git clone "https://${GITLAB_USR}:${GITLAB_PAT}@gitlab.com/$dd/$2.git" \
    "${PGITDIR}/$2"
}

function ghcl() {
  for pkg in "$@"; do
    git clone \
      "https://${GITHUB_ID}:${GITHUB_PAT}@github.com/${GITHUB_ID}/${pkg}" \
      "${PGITDIR}/${pkg}"
  done
}

#PGITDIR="$HOME/projects/perso"

if command -v bat &> /dev/null; then
  batdiff() {
    git diff --name-only --relative --diff-filter=d | xargs bat --diff
  }
  alias gd=batdiff
fi
