# Core setup logic applicable to all POSIX-compatible login shells.

# Always expand aliases in Bash shells (normally, this option is only set by default for interactive shells).
if [ -n "$BASH_VERSION" ]; then
   shopt -s expand_aliases
fi

# Activate fzf shell integration (adds key bindings).
# See https://junegunn.github.io/fzf/shell-integration/
# This functionality only exists in fzf version 0.48.0 and later.
fzf_version=$(fzf --version | cut -d' ' -f1)
if printf '%s\n' "0.48.0" "$fzf_version" | sort -V -C; then
   if [ -n "$BASH_VERSION" ]; then
      FZF_CTRL_R_COMMAND= eval "$(fzf --bash)"
   fi
   if [ -n "$ZSH_VERSION" ]; then
      FZF_CTRL_R_COMMAND= source <(fzf --zsh)
   fi
fi

if [ -f ~/.shell_setup/shell_aliases/shell_aliases.sh ]; then
    . ~/.shell_setup/shell_aliases/shell_aliases.sh
fi

if [ -f ~/.shell_setup/shell_functions/shell_functions.sh ]; then
    . ~/.shell_setup/shell_functions/shell_functions.sh
fi

# Make my custom binaries available
export PATH=${PATH}:$HOME/bin

# Do not save commands that start with a space to the history list
export HISTCONTROL=ignorespace

