#------------------------------#
# Miscellaneous Bash Functions #
#------------------------------#

# Resolve an alias name to the command it's mapped to
function getalias() {
   local alias_name="$1"
   alias | grep "^alias ${alias_name}=" | sed -E "s/^alias ${alias_name}='(.*)'/\1/"
}

# Alias for checking if the current working directory is in a git repo
function in_git_repo() {
   git in-repo
}

