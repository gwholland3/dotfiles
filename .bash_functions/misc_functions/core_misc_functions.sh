#------------------------------#
# Miscellaneous Bash Functions #
#------------------------------#

# A function for testing/debugging
function my_test_function() {
   echo "$0"

   for arg in "$@"
   do
      echo "$arg"
   done

   echo "EXP_VAR: $EXP_VAR"
}

# Finds the Bazel label for a source file. Searches in the current workspace by default,
# but can take a second argument for an alternative repo to search in.
function bflabel() {
   # Output an error message and exit if there isn't at least one argument
   if [ $# -lt 1 ]; then
      echo "Error: this function requires at least one argument"
      return 1
   fi

   local file_regex="$1"
   local bazel_repo="@"
   if [ $# -gt 1 ]; then
      bazel_repo="$2"
   fi

   bq "filter('$file_regex', kind('source file', '${bazel_repo}//...:*'))" 2>/dev/null
}

# Invoke `cd` as normal, then run `ll` in the resulting directory
function cdl() {
   # The `cd` Bash builtin treats a null argument (e.g. `cd ""`) as equivalent to
   # `.`, i.e. the current directory. So, if the user invoked `cdl` with no argument,
   # we invoke `cd` with no argument.
   if [ -z "$1" ]
   then
      cd
   else
      cd "$1"
   fi

   ll
}

# Resolve an alias name to the command it's mapped to
function getalias() {
   local alias_name="$1"
   alias | grep "^alias ${alias_name}=" | sed -E "s/^alias ${alias_name}='(.*)'/\1/"
}

# simple helper function to activate a relevant Python venv
function venv() {
   # Search for the venv from the current directoy by default
   local VENV_SEARCH_DIR=.

   # If an argument was provided, use that as the directory to search from
   if [ $# -gt 0 ]
   then
      VENV_SEARCH_DIR="${1}"
   fi

   # Grab the path ot the `activate` script of the first venv we find
   local VENV_ACTIVATE_SCRIPT=$(find "${VENV_SEARCH_DIR}" -regex ".*venv.*/bin/activate" -print -quit)

   # Error if no venv was found
   if [ -z "${VENV_ACTIVATE_SCRIPT}" ]
   then
      local VENV_SEARCH_PATH=$(realpath "${VENV_SEARCH_DIR}")
      echo "Could not find a venv from ${VENV_SEARCH_PATH}"
      return 1
   fi

   # Activate the venv
   source "${VENV_ACTIVATE_SCRIPT}"

   # Inform user which venv was activated
   local VENV_DIR=$(realpath $(dirname $(dirname "${VENV_ACTIVATE_SCRIPT}")))
   echo "Activated ${VENV_DIR}"
}

