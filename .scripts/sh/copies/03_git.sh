# shellcheck shell=bash

# shellcheck disable=SC2016
function git_remote {
    # about 'adds remote $GIT_HOSTING:$1 to current repo'
    group "git"

    echo "Running: git remote add origin ${GIT_HOSTING:?}:$1.git"
    git remote add origin "${GIT_HOSTING}:${1}".git
}

function git_first_push {
    # about 'push into origin refs/heads/master'
    # group 'git'

    echo "Running: git push origin master:refs/heads/master"
    git push origin master:refs/heads/master
}

function git_pub() {
    # about 'publishes current branch to remote origin'
    # group 'git'
    BRANCH=$(git rev-parse --abbrev-ref HEAD)

    echo "Publishing ${BRANCH} to remote origin"
    git push -u origin "${BRANCH}"
}

function git_revert() {
    # about 'applies changes to HEAD that revert all changes after this commit'
    # group 'git'

    git reset "${1:?}"
    git reset --soft "HEAD@{1}"
    git commit -m "Revert to ${1}"
    git reset --hard
}

function git_rollback() {
    # about 'resets the current HEAD to this commit'
    # group 'git'

    function is_clean() {
        if [[ $(git diff --shortstat 2>/dev/null | tail -n1) != "" ]]; then
            echo "Your branch is dirty, please commit your changes"
            kill -INT $$
        fi
    }

    function commit_exists() {
        if git rev-list --quiet "${1:?}"; then
            echo "Commit ${1} does not exist"
            kill -INT $$
        fi
    }

    function keep_changes() {
        while true; do
            # shellcheck disable=SC2162
            read -p "Do you want to keep all changes from rolled back revisions in your working tree? [Y/N]" RESP
            case "${RESP}" in

            [yY])
                echo "Rolling back to commit ${1} with unstaged changes"
                git reset "$1"
                break
                ;;
            [nN])
                echo "Rolling back to commit ${1} with a clean working tree"
                git reset --hard "$1"
                break
                ;;
            *)
                echo "Please enter Y or N"
                ;;
            esac
        done
    }

    if [ -n "$(git symbolic-ref HEAD 2>/dev/null)" ]; then
        is_clean
        commit_exists "$1"

        while true; do
            # shellcheck disable=SC2162
            read -p "WARNING: This will change your history and move the current HEAD back to commit ${1}, continue? [Y/N]" RESP
            case "${RESP}" in

            [yY])
                keep_changes "$1"
                break
                ;;
            [nN])
                break
                ;;
            *)
                echo "Please enter Y or N"
                ;;
            esac
        done
    else
        echo "you're currently not in a git repository"
    fi
}

function git_remove_missing_files() {
    # about "git rm's missing files"
    # group 'git'

    git ls-files -d -z | xargs -0 git update-index --remove
}

# Adds files to git's exclude file (same as .gitignore)
function local-ignore() {
    # about 'adds file or path to git exclude file'
    param '1: file or path fragment to ignore'
    # group 'git'
    echo "$1" >>.git/info/exclude
}

# get a quick overview for your git repo
function git_info() {
    # about 'overview for your git repo'
    # group 'git'

    if [ -n "$(git symbolic-ref HEAD 2>/dev/null)" ]; then
        # print informations
        echo "git repo overview"
        echo "-----------------"
        echo

        # print all remotes and thier details
        for remote in $(git remote show); do
            echo "${remote}":
            git remote show "${remote}"
            echo
        done

        # print status of working repo
        echo "status:"
        if [ -n "$(git status -s 2>/dev/null)" ]; then
            git status -s
        else
            echo "working directory is clean"
        fi

        # print at least 5 last log entries
        echo
        echo "log:"
        git log -5 --oneline
        echo

    else
        echo "you're currently not in a git repository"

    fi
}

function git_stats {
    # about 'display stats per author'
    # group 'git'

    # awesome work from https://github.com/esc/git-stats
    # including some modifications

    if [ -n "$(git symbolic-ref HEAD 2>/dev/null)" ]; then
        echo "Number of commits per author:"
        git --no-pager shortlog -sn --all
        AUTHORS=$(git shortlog -sn --all | cut -f2 | cut -f1 -d' ')
        LOGOPTS=""
        if [ "$1" == '-w' ]; then
            LOGOPTS="${LOGOPTS} -w"
            shift
        fi
        if [ "$1" == '-M' ]; then
            LOGOPTS="${LOGOPTS} -M"
            shift
        fi
        if [ "$1" == '-C' ]; then
            LOGOPTS="${LOGOPTS} -C --find-copies-harder"
            shift
        fi
        for a in ${AUTHORS}; do
            echo '-------------------'
            echo "Statistics for: ${a}"
            echo -n "Number of files changed: "
            # shellcheck disable=SC2086
            git log ${LOGOPTS} --all --numstat --format="%n" --author="${a}" | cut -f3 | sort -iu | wc -l
            echo -n "Number of lines added: "
            # shellcheck disable=SC2086
            git log ${LOGOPTS} --all --numstat --format="%n" --author="${a}" | cut -f1 | awk '{s+=$1} END {print s}'
            echo -n "Number of lines deleted: "
            # shellcheck disable=SC2086
            git log ${LOGOPTS} --all --numstat --format="%n" --author="${a}" | cut -f2 | awk '{s+=$1} END {print s}'
            echo -n "Number of merges: "
            # shellcheck disable=SC2086
            git log ${LOGOPTS} --all --merges --author="${a}" | grep -c '^commit'
        done
    else
        echo "you're currently not in a git repository"
    fi
}

function gittowork() {
    # about 'Places the latest .gitignore file for a given project type in the current directory, or concatenates onto an existing .gitignore'
    # # group 'git'
    param '1: the language/type of the project, used for determining the contents of the .gitignore file'
    example '$ gittowork java'

    result=$(curl -L "https://www.gitignore.io/api/$1" 2>/dev/null)

    if [[ "${result}" =~ ERROR ]]; then
        echo "Query '$1' has no match. See a list of possible queries with 'gittowork list'"
    elif [[ $1 == list ]]; then
        echo "${result}"
    else
        if [[ -f .gitignore ]]; then
            result=$(grep -v "# Created by http://www.gitignore.io" <<<"${result}")
            echo ".gitignore already exists, appending..."
        fi
        echo "${result}" >>.gitignore
    fi
}

function gitignore-reload() {
    # about 'Empties the git cache, and readds all files not blacklisted by .gitignore'
    # # group 'git'
    example '$ gitignore-reload'

    # The .gitignore file should not be reloaded if there are uncommited changes.
    # Firstly, require a clean work tree. The function require_clean_work_tree()
    # was stolen with love from https://www.spinics.net/lists/git/msg142043.html

    # Begin require_clean_work_tree()

    # Update the index
    git update-index -q --ignore-submodules --refresh
    err=0

    # Disallow unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules --; then
        echo >&2 "ERROR: Cannot reload .gitignore: Your index contains unstaged changes."
        git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
        err=1
    fi

    # Disallow uncommited changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules; then
        echo >&2 "ERROR: Cannot reload .gitignore: Your index contains uncommited changes."
        git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
        err=1
    fi

    # Prompt user to commit or stash changes and exit
    if [[ "${err}" == 1 ]]; then
        echo >&2 "Please commit or stash them."
    fi

    # End require_clean_work_tree()

    # If we're here, then there are no uncommited or unstaged changes dangling around.
    # Proceed to reload .gitignore
    if [[ "${err}" == 0 ]]; then
        # Remove all cached files
        git rm -r --cached .

        # Re-add everything. The changed .gitignore will be picked up here and will exclude the files
        # now blacklisted by .gitignore
        echo >&2 "Running git add ."
        git add .
        echo >&2 "Files readded. Commit your new changes now."
    fi
}

function git-changelog() {
    # ---------------------------------------------------------------
    #  ORIGINAL ANSWER: https://stackoverflow.com/a/2979587/10362396 |
    # ---------------------------------------------------------------
    # about 'Creates the git changelog from one point to another by date'
    # # group 'git'
    example '$ git-changelog origin/master...origin/release [md|txt]'

    if [[ "$1" != *"..."* ]]; then
        echo "Please include the valid 'diff' to make changelog"
        return 1
    fi

    # shellcheck disable=SC2155
    local NEXT=$(date +%F)

    if [[ "$2" == "md" ]]; then
        echo "# CHANGELOG $1"

        # shellcheck disable=SC2162
        git log "$1" --no-merges --format="%cd" --date=short | sort -u -r | while read DATE; do
            echo
            echo "### ${DATE}"
            git log --no-merges --format=" * (%h) %s by [%an](mailto:%ae)" --since="${DATE} 00:00:00" --until="${DATE} 24:00:00"
            NEXT=${DATE}
        done
    else
        echo "CHANGELOG $1"
        echo ----------------------

        # shellcheck disable=SC2162
        git log "$1" --no-merges --format="%cd" --date=short | sort -u -r | while read DATE; do
            echo
            echo "[${DATE}]"
            git log --no-merges --format=" * (%h) %s by %an <%ae>" --since="${DATE} 00:00:00" --until="${DATE} 24:00:00"
            # shellcheck disable=SC2034
            NEXT=${DATE}
        done
    fi
}

alias g='git'
alias get='git'
alias got='git '

# add
alias ga='git add'
alias gall='git add -A'
alias gap='git add -p'
alias gav='git add -v'
alias gau='git add --update'

# branch
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gbl='git branch --list'
alias gbla='git branch --list --all'
alias gblr='git branch --list --remotes'
alias gbm='git branch --move'
alias gbr='git branch --remotes'
alias gbt='git branch --track'

# for-each-ref
alias gbc='git for-each-ref --format="%(authorname) %09 %(if)%(HEAD)%(then)*%(else)%(refname:short)%(end) %09 %(creatordate)" refs/remotes/ --sort=authorname DESC' # FROM https://stackoverflow.com/a/58623139/10362396

# commit
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gcaa='git commit -a --amend -C HEAD' # Add uncommitted and unstaged changes to the last commit
alias gcam='git commit -v -am'
alias gcamd='git commit --amend'
alias gc!='git commit -v --amend'
alias gca!='git commit -v -a --amend'
alias gcn!='git commit -v --amend --no-edit'
alias gcm='git commit -v -m'
alias gci='git commit --interactive'
alias gcsam='git commit -S -am'

# checkout
alias gcb='git checkout -b'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gcobu='git checkout -b ${USER}/'
alias gcom='git checkout $(get_default_branch)'
alias gcpd='git checkout $(get_default_branch); git pull; git branch -D'
alias gct='git checkout --track'

# clone
alias gcl='git clone'

# clean
alias gclean='git clean -fd'

# cherry-pick
alias gcp='git cherry-pick'
alias gcpx='git cherry-pick -x'

# diff
alias gd='git diff'
alias gds='git diff --staged'
alias gdt='git difftool'

# archive
alias gexport='git archive --format zip --output'

# fetch
alias gf='git fetch --all --prune'
alias gft='git fetch --all --prune --tags'
alias gftv='git fetch --all --prune --tags --verbose'
alias gfv='git fetch --all --prune --verbose'
alias gmu='git fetch origin -v; git fetch upstream -v; git merge upstream/$(get_default_branch)'
alias gup='git fetch && git rebase'
alias gfa='gf'

# log
alias gg='git log --graph --pretty=format:'\''%C(bold)%h%Creset%C(magenta)%d%Creset %s %C(yellow)<%an> %C(cyan)(%cr)%Creset'\'' --abbrev-commit --date=relative'
alias ggf='git log --graph --date=short --pretty=format:'\''%C(auto)%h %Cgreen%an%Creset %Cblue%cd%Creset %C(auto)%d %s'\'''
alias ggs='gg --stat'
alias ggup='git log --branches --not --remotes --no-walk --decorate --oneline' # FROM https://stackoverflow.com/questions/39220870/in-git-list-names-of-branches-with-unpushed-commits
alias gll='git log --graph --pretty=oneline --abbrev-commit'
alias gnew='git log HEAD@{1}..HEAD@{0}' # Show commits since last pull, see http://blogs.atlassian.com/2014/10/advanced-git-aliases/
alias gwc='git whatchanged'
alias ghist='git log --pretty=format:'\''%h %ad | %s%d [%an]'\'' --graph --date=short'                                          # Use it to be fast and without color.
alias gprogress='git log --pretty=format:'\''%C(yellow)%h %Cblue%ad %Creset%s%Cgreen [%cn] %Cred%d'\'' --decorate --date=short' #Usually use "git progress" in the file .gitconfig. The new alias from Git friends will be truly welcome.

# ls-files
alias gu='git ls-files . --exclude-standard --others' # Show untracked files
alias glsut='gu'
alias glsum='git diff --name-only --diff-filter=U' # Show unmerged (conflicted) files

# gui
alias ggui='git gui'

# home
alias ghm='cd "$(git rev-parse --show-toplevel)"' # Git home

# merge
alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gms='git merge --squash'

# mv
alias gmv='git mv'

# patch
alias gpatch='git format-patch -1'

# push
alias gp='git push'
alias gpd='git push --delete'
alias gpf='git push --force-with-lease'
alias gpff='git push --force'
alias gpo='git push origin HEAD'
alias gpom='git push origin $(get_default_branch)'
alias gpu='git push --set-upstream'
alias gpunch='git push --force-with-lease'
alias gpuo='git push --set-upstream origin'
alias gpuoc='git push --set-upstream origin $(git symbolic-ref --short HEAD)'

# pull
alias gl='git pull'
alias glp='git pull --prune'
alias glum='git pull upstream $(get_default_branch)'
alias gpl='git pull'
alias gpp='git pull && git push'
alias gpr='git pull --rebase'

# remote
alias gr='git remote'
alias gra='git remote add'
alias grv='git remote -v'

# rm
alias grm='git rm'
alias grmc='git rm --cached' # Removes the file only from the Git repository, but not from the filesystem. This is useful to undo some of the changes you made to a file before you commit it.

# rebase
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbm='git rebase $(get_default_branch)'
alias grbmi='git rebase $(get_default_branch) --interactive'
alias grbma='GIT_SEQUENCE_EDITOR=: git rebase $(get_default_branch) --interactive --autosquash'
alias gprom='git fetch origin $(get_default_branch) && git rebase origin/$(get_default_branch) && git update-ref refs/heads/$(get_default_branch) origin/$(get_default_branch)' # Rebase with latest remote

# reset
alias gus='git reset HEAD' # read as: 'git unstage'
alias grh='git reset'      # equivalent to: git reset HEAD
alias grh!='git reset --hard'
alias gpristine='git reset --hard && git clean -dfx'

# status
alias gs='git status'
alias gss='git status -s'

# shortlog
alias gcount='git shortlog -sn'
alias gsl='git shortlog -sn'

# show
alias gsh='git show'
alias gshn='git show --name-only'
alias gshns='git show --name-status'

# svn
alias gsd='git svn dcommit'
alias gsr='git svn rebase' # Git SVN

# stash
alias gst='git stash'
alias gstb='git stash branch'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'  # kept due to long-standing usage
alias gstpo='git stash pop' # recommended for it's symmetry with gstpu (push)

## 'stash push' introduced in git v2.13.2
alias gstpu='git stash push'
alias gstpum='git stash push -m'

## 'stash save' deprecated since git v2.16.0, alias is now push
alias gsts='git stash push'
alias gstsm='git stash push -m'

# submodules
alias gsu='git submodule update --init --recursive'

# switch
# these aliases requires git v2.23+
alias gsw='git switch'
alias gswc='git switch --create'
alias gswm='git switch $(get_default_branch)'
alias gswt='git switch --track'

# tag
alias gt='git tag'
alias gta='git tag -a'
alias gtd='git tag -d'
alias gtl='git tag -l'

case $OSTYPE in
darwin*)
    alias gtls="git tag -l | gsort -V"
    ;;
*)
    alias gtls='git tag -l | sort -V'
    ;;
esac

# functions
function gdv() {
    git diff --ignore-all-space "$@" | vim -R -
}

function get_default_branch() {
    branch=$(git symbolic-ref refs/remotes/origin/HEAD)
    ${branch#refs/remotes/origin/}
}
