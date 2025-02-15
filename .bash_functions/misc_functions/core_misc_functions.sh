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

