#----------------------------#
# Miscellaneous Bash Aliases #
#----------------------------#

# Various shorthand ls commands
alias ls='ls -Gh'
alias l.='ls -dlrt .* -Gh'
alias ll='ls -lrt -Gh'

# Print your public IP address
alias pubip='curl ipinfo.io/ip; echo'

# Produces a sound
alias notify='printf "\a"'

# cd into my dotfiles repo
alias dots='cd ~/Grant/GitHub\ Repos/dotfiles/'

# Shorthand git commands
alias gs='git status'
alias gd='git diff'
alias gl='git log'

# For use in git-related shell functions: return from the function if not in a git repo
alias git_repo_check='git in-repo || return 1'

# For use in git-related shell functions: return from the function if there are local changes, with error message
alias git_wt_clean_check='git wt-clean || (echo "You have local changes. Please commit or stash them."; return 1) || return 1'

# Produces a nicely-colored diff
alias pretty_diff='git diff --no-index --'

# Shorthand Bazel commands
alias bb='bazel build'
alias br='bazel run'
alias bt='bazel test'

# Upgrades all outdated homebrew casks, except for brave-browser (because I don't like to restart my browser frequently)
alias brew_cask_up='brew upgrade --cask $(brew outdated --cask --greedy | cut -d " " -f 1 | grep -v brave-browser | tr "\n" " ")'

