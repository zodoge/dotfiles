# shellcheck shell=bash

if command -v apt &> /dev/null; then
  # Cleans the cache.
  alias debc='sudo apt clean && sudo apt autoclean'

  # Displays a file's package.
  alias debf='apt-file search --regexp'

# Installs packages from repositories.
  alias debi='sudo apt install --no-install-recommends'

  # Installs packages from files.
  alias debI='sudo dpkg -i'

	# Displays package information.
	alias debq='apt-cache show'

	  # Updates the package lists.
	alias debu='sudo apt update && apt list --upgradable'

	# Upgrades outdated packages.
	alias debU='sudo apt update && sudo apt dist-upgrade && debc'

	# Removes packages.
	alias debx='sudo apt remove'

	# Removes packages, their configuration, and unneeded dependencies.
	alias debX='sudo apt remove --purge && sudo apt autoremove --purge'

	# Searches for packages.
	if command -v aptitude &> /dev/null; then
		alias debs='aptitude -F "* %p -> %d \n(%v/%V)" --no-gui --disable-columns search'
		# Removes all kernel images and headers, except for the ones in use.
		alias deb-kclean='sudo aptitude remove -P "?and(~i~nlinux-(ima|hea) ?not(~n$(uname -r)))"'
	else
		alias debs='apt-cache search'
	fi

	  # Creates a basic deb package.
  alias deb-build='time dpkg-buildpackage -rfakeroot -us -uc'
fi