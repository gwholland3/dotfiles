# Core setup logic applicable to all POSIX-compatible login shells.

# Always expand aliases in Bash shells (normally, this option is only set by default for interactive shells).
if [ -n "$BASH_VERSION" ]; then
   shopt -s expand_aliases
fi

if [ -f ~/.bash_aliases/bash_aliases.sh ]; then
    . ~/.bash_aliases/bash_aliases.sh
fi

if [ -f ~/.bash_functions/bash_functions.sh ]; then
    . ~/.bash_functions/bash_functions.sh
fi

# Make my custom binaries available
export PATH=${PATH}:$HOME/bin

# Do not save commands that start with a space to the history list
export HISTCONTROL=ignorespace

