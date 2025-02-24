# shellcheck shell=bash
# Creates archive file
#
# Authors:
#   Matt Hamilton <m@tthamilton.com>
#

function archive {

	local archive_name path_to_archive _gzip_bin _bzip2_bin _xz_bin _zstd_bin

	if (( $# < 2 )); then
	  cat >&2 <<EOF
	usage: $0 [archive_name.zip] [/path/to/include/into/archive ...]

	Where 'archive.zip' uses any of the following extensions:

	.tar.gz, .tar.bz2, .tar.xz, .tar.lzma, .tar.zst, .tar, .zip, .rar, .7z

	There is no '-v' switch; all operations are verbose.
EOF
	return 1
	fi

	# we are quitting (above) if there are not exactly 2 vars,
	#  so we don't need any argc check here.

	# strip the path, just in case one is provided for some reason
	archive_name="${1:t}"
	# let paths be handled by actual archive helper
	path_to_archive="${@:2}"

	# here, we check for dropin/multi-threaded replacements
	# this should eventually be moved to modules/archive/init.zsh
	# as a global alias
	if (( $+commands[pigz] )); then
	  _gzip_bin='pigz'
	else
	  _gzip_bin='gzip'
	fi

	if (( $+commands[pixz] )); then
	  _xz_bin='pixz'
	else
	  _xz_bin='xz'
	fi

	if (( $+commands[lbzip2] )); then
	  _bzip2_bin='lbzip2'
	elif (( $+commands[pbzip2] )); then
	  _bzip2_bin='pbzip2'
	else
	  _bzip2_bin='bzip2'
	fi

	_zstd_bin='zstd'

	case "${archive_name}" in
	  (*.tar.gz|*.tgz) tar -cvf "${archive_name}" --use-compress-program="${_gzip_bin}" "${=path_to_archive}" ;;
	  (*.tar.bz2|*.tbz|*.tbz2) tar -cvf "${archive_name}" --use-compress-program="${_bzip2_bin}" "${=path_to_archive}" ;;
	  (*.tar.xz|*.txz) tar -cvf "${archive_name}" --use-compress-program="${_xz_bin}" "${=path_to_archive}" ;;
	  (*.tar.lzma|*.tlz) tar -cvf "${archive_name}" --lzma "${=path_to_archive}" ;;
	  (*.tar.zst|*.tzst) tar -cvf "${archive_name}" --use-compress-program="${_zstd_bin}" "${=path_to_archive}" ;;
	  (*.tar) tar -cvf "${archive_name}" "${=path_to_archive}" ;;
	  (*.zip|*.jar) zip -r "${archive_name}" "${=path_to_archive}" ;;
	  (*.rar) rar a "${archive_name}" "${=path_to_archive}" ;;
	  (*.7z) 7za a "${archive_name}" "${=path_to_archive}" ;;
	  (*.gz) print "\n.gz is only useful for single files, and does not capture permissions. Use .tar.gz" ;;
	  (*.bz2) print "\n.bzip2 is only useful for single files, and does not capture permissions. Use .tar.bz2" ;;
	  (*.xz) print "\n.xz is only useful for single files, and does not capture permissions. Use .tar.xz" ;;
	  (*.lzma) print "\n.lzma is only useful for single files, and does not capture permissions. Use .tar.lzma" ;;
	  (*) print "\nunknown archive type for archive: ${archive_name}" ;;
	esac

}

function unarchive {

	local remove_archive
	local success
	local file_name
	local file_path
	local extract_dir
	local _gzip_bin _bzip2_bin _xz_bin _zstd_bin

	if (( $# == 0 )); then
	  cat >&2 <<EOF
	usage: $0 [-option] [file ...]

	options:
	    -r, --remove    remove archive

	Report bugs to <sorin.ionescu@gmail.com>.
EOF
	fi

	remove_archive=1
	if [[ "$1" == "-r" || "$1" == "--remove" ]]; then
	  remove_archive=0
	  shift
	fi

	# here, we check for dropin/multi-threaded replacements
	# this should eventually be moved to modules/archive/init.zsh
	# as a global alias
	if (( $+commands[unpigz] )); then
	  _gzip_bin='unpigz'
	else
	  _gzip_bin='gunzip'
	fi

	if (( $+commands[pixz] )); then
	  _xz_bin='pixz -d'
	else
	  _xz_bin='xz'
	fi

	if (( $+commands[lbunzip2] )); then
	  _bzip2_bin='lbunzip2'
	elif (( $+commands[pbunzip2] )); then
	  _bzip2_bin='pbunzip2'
	else
	  _bzip2_bin='bunzip2'
	fi

	_zstd_bin='zstd'

	while (( $# > 0 )); do
	  if [[ ! -s "$1" ]]; then
	    print "$0: file not valid: $1" >&2
	    shift
	    continue
	  fi

	  success=0
	  file_name="${1:t}"
	  file_path="${1:A}"
	  extract_dir="${file_name:r}"
	  case "$1:l" in
	    (*.tar.gz|*.tgz) tar -xvf "$1" --use-compress-program="${_gzip_bin}" ;;
	    (*.tar.bz2|*.tbz|*.tbz2) tar -xvf "$1" --use-compress-program="${_bzip2_bin}" ;;
	    (*.tar.xz|*.txz) tar -xvf "$1" --use-compress-program="${_xz_bin}" ;;
	    (*.tar.zma|*.tlz) tar --lzma --help &> /dev/null \
	      && tar --lzma -xvf "$1" \
	      || lzcat "$1" | tar -xvf - ;;
	    (*.tar.zst|*.tzst) tar -xvf "$1" --use-compress-program="${_zstd_bin}" ;;
	    (*.tar) tar -xvf "$1" ;;
	    (*.gz) gunzip "$1" ;;
	    (*.bz2) bunzip2 "$1" ;;
	    (*.xz) unxz "$1" ;;
	    (*.lzma) unlzma "$1" ;;
	    (*.Z) uncompress "$1" ;;
	    (*.zip|*.jar) unzip "$1" -d $extract_dir ;;
	    (*.rar) ( (( $+commands[unrar] )) \
	      && unrar x -ad "$1" ) \
	      || ( (( $+commands[rar] )) \
	      && rar x -ad "$1" ) \
	      || unar -d "$1" ;;
	    (*.7z) 7za x "$1" ;;
	    (*.deb)
	      mkdir -p "$extract_dir/control"
	      mkdir -p "$extract_dir/data"
	      cd "$extract_dir"; ar vx "${file_path}" > /dev/null
	      cd control; tar xvf ../control.tar.*
	      cd ../data; tar xvf ../data.tar.*
	      cd ..; rm control.tar.* data.tar.* debian-binary
	      cd ..
	    ;;
	    (*)
	      print "$0: cannot extract: $1" >&2
	      success=1
	    ;;
	  esac

	  (( success = $success > 0 ? $success : $? ))
	  (( $success == 0 )) && (( $remove_archive == 0 )) && rm "$1"
	  shift
	done

}

function lsarchive {

	local verbose

	if (( $# == 0 )); then
	  cat >&2 <<EOF
	usage: $0 [-option] [file ...]

	options:
	    -v, --verbose    verbose archive listing

	Report bugs to <sorin.ionescu@gmail.com>.
EOF
	fi

	if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
	  verbose=0
	  shift
	fi

	while (( $# > 0 )); do
	  if [[ ! -s "$1" ]]; then
	    print "$0: file not valid: $1" >&2
	    shift
	    continue
	  fi

	  case "$1:l" in
	    (*.tar.gz|*.tgz) tar t${verbose:+v}vzf "$1" ;;
	    (*.tar.bz2|*.tbz|*.tbz2) tar t${verbose:+v}jf "$1" ;;
	    (*.tar.xz|*.txz) tar --xz --help &> /dev/null \
	      && tar --xz -t${verbose:+v}f "$1" \
	      || xzcat "$1" | tar t${verbose:+v}f - ;;
	    (*.tar.zma|*.tlz) tar --lzma --help &> /dev/null \
	      && tar --lzma -t${verbose:+v}f "$1" \
	      || lzcat "$1" | tar x${verbose:+v}f - ;;
	    (*.tar.zst|*.tzst) tar -I zstd -t${verbose:+v}f "$1" ;;
	    (*.tar) tar t${verbose:+v}f "$1" ;;
	    (*.zip|*.jar) unzip -l${verbose:+v} "$1" ;;
	    (*.rar) ( (( $+commands[unrar] )) \
	      && unrar ${${verbose:+v}:-l} "$1" ) \
	      || ( (( $+commands[rar] )) \
	      && rar ${${verbose:+v}:-l} "$1" ) \
	      || lsar ${verbose:+-l} "$1" ;;
	    (*.7z) 7za l "$1" ;;
	    (*)
	      print "$0: cannot list: $1" >&2
	      success=1
	    ;;
	  esac

	  shift
	done

}