if command -v pacman &> /dev/null; then
  # Pacman - https://wiki.archlinux.org/index.php/Pacman_Tips
  alias pacupg='sudo pacman -Syu'
  alias pacin='sudo pacman -S'
  alias paclean='sudo pacman -Sc'
  alias pacins='sudo pacman -U'
  alias paclr='sudo pacman -Scc'
  alias pacre='sudo pacman -R'
  alias pacrem='sudo pacman -Rns'
  alias pacrep='pacman -Si'
  alias pacreps='pacman -Ss'
  alias pacloc='pacman -Qi'
  alias paclocs='pacman -Qs'
  alias pacinsd='sudo pacman -S --asdeps'
  alias pacmir='sudo pacman -Syy'
  alias paclsorphans='sudo pacman -Qdt'
  alias pacrmorphans='sudo pacman -Rs $(pacman -Qtdq)'
  alias pacfileupg='sudo pacman -Fy'
  alias pacfiles='pacman -F'
  alias pacls='pacman -Ql'
  alias pacown='pacman -Qo'
  alias pacupd="sudo pacman -Sy"
  alias pacmanallkeys='sudo pacman-key --refresh-keys'
  function paclist() {
    pacman -Qqe | xargs -I{} -P0 --no-run-if-empty pacman -Qs --color=auto "^{}\$"
  }

fi

if command -v yay &> /dev/null; then
  alias yaconf='yay -Pg'
  alias yaclean='yay -Sc'
  alias yaclr='yay -Scc'
  alias yaupg='yay -Syu'
  alias yasu='yay -Syu --noconfirm'
  alias yain='yay -S'
  alias yains='yay -U'
  alias yare='yay -R'
  alias yarem='yay -Rns'
  alias yarep='yay -Si'
  alias yareps='yay -Ss'
  alias yaloc='yay -Qi'
  alias yalocs='yay -Qs'
  alias yalst='yay -Qe'
  alias yaorph='yay -Qtd'
  alias yainsd='yay -S --asdeps'
  alias yamir='yay -Syy'
  alias yaupd="yay -Sy"
fi
