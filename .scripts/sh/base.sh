function  _check_args() {
  if [ $# != 2 ]; then
    echo "Expect two arguments: directory and files extention"
  fi
}

function find_files() {
  #_check_args
  # "$1" => directory, "$2" => extension of files to source
  find -L "$1" -type f -name "*.$2" | while read -r file; do
    echo "$file"
  done
}

source_files() {
  #_check_args
  # "$1" => directory, "$2" => extension of files to source
  find -L "$1" -type f -name "*.$2" | while read -r file; do
    source "$file"
  done
}
