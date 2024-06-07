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

# Upgrades all outdated homebrew casks, except for brave-browser (because I don't like to restart my browser frequently)
alias brew_cask_up='brew upgrade --cask $(brew outdated --cask --greedy | cut -d " " -f 1 | grep -v brave-browser | tr "\n" " ")'

# cd into my dotfiles repo
alias dots='cd ~/Grant/Github\ Repos/dotfiles/'

