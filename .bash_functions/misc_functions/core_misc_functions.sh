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

# A simple wrapper function that allows you to run a command
# from a subdirectory and end up back in your original directory,
# while preserving the exit status of your command.
#
# Example usage: run_from subdir ls -l
function run_from() {
   # Output an error message and exit if there isn't at least two arguments.
   if [ $# -lt 2 ]; then
      echo "Error: this function requires at least two arguments"
      return 1
   fi

   # Capture user arguments.
   local directory="$1"
   local cmd=("${@:2}")

   # Cd into the specified directory.
   pushd "$directory" >/dev/null

   # Run the user-provided command.
   "${cmd[@]}"

   # Save the exit status of the user-provided command.
   local exit_status=$?

   # Return to the original directory.
   popd >/dev/null

   # Pipe through the exit status.
   return $exit_status
}

# A wrapper around `find` for quick searches. Searches in the current
# directory by default, but can take a second argument for an alternative
# starting directory.
function search() {
   # Output an error message and exit if there isn't at least one argument
   if [ $# -lt 1 ]; then
      echo "Error: this function requires at least one argument"
      return 1
   fi

   local search_regex="$1"

   local starting_location="."
   if [ $# -gt 1 ]; then
      starting_location="$2"
   fi

   # You need to wrap the search regex in `.*` for it to match partial matches
   find "$starting_location" -regex ".*${search_regex}.*"
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
   alias | rg "^alias ${alias_name}=" | sed -E "s/^alias ${alias_name}='(.*)'/\1/"
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

