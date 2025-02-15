# This file is only partially representative of my actual .bash_profile file.
# It contains the common commands that I would want to run on nearly any system.

# My .bash_profile file - the starting point for most of my Bash customization.

if [ -f ~/.bash_aliases/bash_aliases.sh ]; then
    . ~/.bash_aliases/bash_aliases.sh
fi

# Always expand aliases (normally, this is only true by default for interactive shells)
shopt -s expand_aliases

if [ -f ~/.bash_functions/bash_functions.sh ]; then
    . ~/.bash_functions/bash_functions.sh
fi

# Make my custom binaries available
export PATH=${PATH}:$HOME/bin

