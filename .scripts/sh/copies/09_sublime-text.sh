alias st=subl
alias stt='subl .'


function find_project() {
   local PROJECT_NAME="$1"
   local FINAL_DEST="${SUBL_DIR}/${PROJECT_NAME}.sublime-project"
  if [[ -f "$FINAL_DEST"  ]]; then
    subl $FINAL_DEST
  else
    echo "No sublime text project $1. Found"
  fi
}

alias stp=find_project