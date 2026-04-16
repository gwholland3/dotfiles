#------------------------------#
# Bash Functions for Git       #
#------------------------------#

# Shorthand git commands
function gs() { g status "$@"; }
function ga() { g add "$@"; }
function gc() { g commit "$@"; }
function gd() { g diff "$@"; }
function gl() { g log "$@"; }

function nohooks() {
   # Output an error message and exit if there isn't at least one argument.
   if [ $# -lt 1 ]; then
      echo "Error: this function requires at least one argument"
      return 1
   fi

   GIT_CONFIG_COUNT=1 \
   GIT_CONFIG_KEY_0=core.hooksPath \
   GIT_CONFIG_VALUE_0=/dev/null \
   "$@"
}

# A version of `git bisect run` that uses a login shell. This makes e.g. functions available.
function git_bisect_lrun() {
   g bisect run sh -l -c '"$0" "$@"'
}
alias g_bisect_lrun='git_bisect_lrun'

# Runs `git prune` and also deletes the associated log file
function git_auto_prune() {
   # Return if not in a git repo
   git_repo_check

   g prune \
   && rm "$(g rev-parse --show-toplevel)/.git/gc.log"
}
alias g_auto_prune='git_auto_prune'

# Checks whether one commit "contains" another
function git_contains() {
   # Return if not in a git repo
   git_repo_check

   local candidate_child_commit="$1"
   local candidate_parent_commit="$2"

   g merge-base --is-ancestor "$candidate_parent_commit" "$candidate_child_commit" \
      && echo yes \
      || echo no
}
alias g_contains='git_contains'

# Initiate an interactive rebase on just the commits in the current branch that
# have diverged from the default branch.
function git_irebase_self() {
   g rebase -i $(g merge-base HEAD $(g mainb))
}
alias g_irebase_self='git_irebase_self'

# Update the repo's default branch to what origin is pointing to.
function git_syncm() {
   g fetch origin --update-head-ok $(g mainb):$(g mainb)
}
alias g_syncm='git_syncm'

# Checkout your local version of the repo's default branch
function git_go_main() {
   g checkout $(g mainb)
}
alias g_go_main='git_go_main'

# Activate fuzzy search on git branches, and checkout the selected one.
function git_findb() {
   # Return if not in a git repo
   git_repo_check

   local selected_branch=$(g branch --format='%(refname:short)' | fzf)
   if [ -n "$selected_branch" ]; then
      g checkout "$selected_branch"
   fi
}
alias g_findb='git_findb'

# Commit all changes, including untracked files.
function git_commita() {
   # Return if not in a git repo
   git_repo_check

   # Get any user-provided args to `git commit`
   local git_commit_args=("${@}")

   g add -A
   g commit "${git_commit_args[@]}"
}
alias g_commita='git_commita'

# Output the name of the repo's default branch
function git_mainb() {
   # Return if not in a git repo
   git_repo_check

   # If there is a remote called 'origin', return the branch pointed to by its HEAD.
   if g remote | rg origin >/dev/null; then
      basename $(g symbolic-ref --short refs/remotes/origin/HEAD)
      return 0
   fi

   # Check if any common default branches exist, and return the first one found if so.
   for b in main master trunk; do
      if [ -n "$(g branch --list $b)" ]; then
         echo $b
         return 0
      fi
   done

   # Fall back to the default branch used on init as a last resort.
   g config --get init.defaultBranch
}
alias g_mainb='git_mainb'

# Compares the diff of two commits using git range-diff
function git_commit_diff() {
   # Output an error message and exit if there aren't two arguments
   if [ $# -ne 2 ]; then
      echo "Error: this function requires two arguments"
      return 1
   fi

   local commit1="$1"
   local commit2="$2"

   g range-diff "${commit1}"^! "${commit2}"^!
}
alias g_commit_diff='git_commit_diff'

# Outputs a diff of two files, but only comparing the specified chunk of each file, and at arbitrary git revisions.
function git_diff_chunks() {
   # Return if not in a git repo
   git_repo_check

   # Output an error message and exit if there aren't eight arguments
   if [ $# -ne 8 ]; then
      echo "Error: this function requires eight arguments"
      return 1
   fi

   local first_file_path="$1"
   local first_file_commit="$2"
   local first_file_start_line="$3"
   local first_file_end_line="$4"

   local second_file_path="$5"
   local second_file_commit="$6"
   local second_file_start_line="$7"
   local second_file_end_line="$8"

   diff -u \
      <(g show "${first_file_commit}":"${first_file_path}" | sed -n "${first_file_start_line},${first_file_end_line}p") \
      <(g show "${second_file_commit}":"${second_file_path}" | sed -n "${second_file_start_line},${second_file_end_line}p")
}
alias g_diff_chunks='git_diff_chunks'

# Finds which commits have deleted a line based on user-provided line regex. By default,
# only searches three months back to reduce runtime, but this (and other `git log` args)
# can be overridden via additional arguments to this function that are passed to `git log`.
function git_ldel_commit() {
   # Output an error message and exit if there isn't at least one argument
   if [ $# -lt 1 ]; then
      echo "Error: this function requires at least one argument"
      return 1
   fi

   # User-provided regex for the deleted line to search for
   local line_regex="$1"

   # Any additional args to pass to the `git log` command, such as specifying filepaths
   # or requesting a longer search period.
   #
   # Store these as a Bash array so we can expand them into separate words later.
   local git_log_args=("${@:2}")

   # This is how Git represents line deletions in its patch output. We'll use this to
   # filter down to just commits that actually delete the line, not just contain it in
   # the patch output.
   local deletion_regex="^- "

   # Use `git log` to search for all commits that contain the line regex in their patch diff.
   # This will also return commits that only _add_ the line regex, rather than delete it, so
   # we evaluate every returned candidate commit to see if its patch diff demonstrates deletion.
   #
   # Commits that pass this filter are displayed via `git show`, which emulates `git log` output.
   #
   # By default, we only look for commits up to three months back, because otherwise this search
   # gets expensive. This can be overridden by the user if necessary.
   g log -G"${line_regex}" --since='three months ago' --pretty='tformat:%H' "${git_log_args[@]}" |
      # Check if the read-in line has non-zero length as a secondary condition for entering the while
      # loop, to protect against outputs without a trailing newline.
      while IFS= read -r candidate_commit || [ -n "${candidate_commit}" ]; do
         g show "${candidate_commit}" | rg --quiet "${deletion_regex}.*${line_regex}" && g show "${candidate_commit}" --no-patch
      done
}
alias g_ldel_commit='git_ldel_commit'

# Takes two Git revisions as arguments, which are assumed to be an old head commit
# on a PR and a new head commit. Performs a diff of the two revisions, given the
# context that both are being proposed to merge to the main branch.
function git_pr_diff() {
   # Return if not in a git repo
   git_repo_check

   # Output an error message and exit if there aren't two arguments
   if [ $# -ne 2 ]; then
      echo "Error: this function requires two arguments"
      return 1
   fi

   local old_ref="$1"
   local new_ref="$2"

   g range-diff $(g mainb)@{upstream} "${old_ref}" "${new_ref}"
}
alias g_pr_diff='git_pr_diff'

# Squash all the commits on the current feature branch into one, keeping the commit message
# of the first.
#
# Note that you can provide an argument to indicate that you are merging to
# a destination branch other than the default repo branch, and a subsequent `-l` flag to
# indicate that merge-base should look at the local version of the destination branch,
# rather than the remote one.
function git_squash() {
   # Return if not in a git repo
   git_repo_check

   # Return if there are local changes
   git_wt_clean_check

   # Determine the name of the destination branch that the current feature branch is
   # being merged into. This allows us to deduce the first commit on the feature branch.
   local destination_branch="origin/$(g mainb)"
   if [ $# -gt 0 ]; then
      destination_branch="origin/$1"
      if [ $# -gt 1 ] && [ "$2" == "-l" ]; then
         destination_branch="$1"
      fi
   fi

   # Find the merge-base commit between the feature and destination branches.
   local merge_base_commit
   merge_base_commit="$(g merge-base HEAD "$destination_branch")"

   # If the previous command failed, assume the provided destination branch name was bad
   # and bail out.
   if [ $? -ne 0 ]; then
      echo "Invalid destination branch name: $destination_branch"
      return 1
   fi

   # Reset us back to the merge-base commit, but retain all the changes made on the
   # feature branch so far.
   g reset --soft "$merge_base_commit"
   
   # Grab the commit message from the first commit on the feature branch. This is the message
   # we'll use for our final squashed commit.
   local first_commit_msg="$(g log --reverse --format=%B HEAD..HEAD@{1} | head -n 1)"

   # Create a new, squashed commit with all the changes on the feature branch.
   g commit -m "$first_commit_msg"
}
alias g_squash='git_squash'

# Same as git_squash, but automatically force pushes after squashing.
function git_squashp() {
   # Save off any arguments so we can pass them along to git_squash.
   local git_squash_args=("${@}")

   g squash "${git_squash_args[@]}"

   # Don't force push if the squash didn't succeed.
   if [ $? -ne 0 ]; then
      echo "Squash failed. Not force pushing."
      return 1
   fi

   g pushfl
}
alias g_squashp='git_squashp'

# Attempt to force delete the specified branch name from both remote and local.
function git_delete_b() {
   # Return if not in a git repo
   git_repo_check

   # Return if there are local changes
   git_wt_clean_check

   local branch_to_delete="$1"

   # If we currently have to to-be-deleted branch checked out,
   # first check out the main branch instead
   local current_branch="$(g rev-parse --abbrev-ref HEAD)"
   if [ "$current_branch" == "$branch_to_delete" ]; then
      echo "Branch to be deleted is currently checked out, switching to repository main branch"
      g checkout "$(g mainb)"
   fi

   # First attempt to delete the branch on the remote, then
   # try to delete it locally. If either branch doesn't exist,
   # git already has its own helpful error messages.
   g push -d origin "$branch_to_delete"
   g branch -D "$branch_to_delete"
}
alias g_delete_b='git_delete_b'

# Check if the worktree is clean. Exit code 0 if there are no local changes, 1 otherwise.
function git_wt_clean() {
   # Return if not in a git repo
   git_repo_check
   
   # The "short" output of `git status` should contain nothing if the worktree is clean
   [ -z "$(g status -s)" ]
}
alias g_wt_clean='git_wt_clean'

# Checkout the main branch and updated it from remote
function git_now() {
   # Return if not in a git repo
   git_repo_check

   # Return if there are local changes
   git_wt_clean_check

   g checkout $(g mainb)
   g pull -p
}
alias g_now='git_now'

# Fetch from origin AND update the default branch locally, but remain on the original branch
# from which you ran the command, with all uncommitted changes preserved
function git_sync() {
   # Return if not in a git repo
   git_repo_check

   # Determine if the worktree is clean. If not, we will need to stash uncommitted changes
   # before checking out the default branch and pop them after coming back to the
   # original branch.
   git_wt_clean
   local wt_clean=$?

   if [ "${wt_clean}" -ne 0 ]; then
      # Stash uncommitted changes, including untracked files
      g stash push -u
   fi

   # Checkout the repo's default branch, fetch from remote, and update the branch
   g checkout "$(g mainb)"
   g pull -p

   # Return to the original branch
   g checkout -

   if [ "${wt_clean}" -ne 0 ]; then
      # Restore any uncommitted changes on the original branch
      g stash pop
   fi
}
alias g_sync='git_sync'

# Checks out a tracking branch for the specified remote branch locally. Automatically syncs
# with the remote first in case the branch was created after your most recent fetch, and
# resets the local tracking branch to its remote upstream if said local branch already exists.
function git_get_branch() {
   # Return if not in a git repo
   git_repo_check

   # Return if there are local changes
   git_wt_clean_check

   # TODO: consider adding a flag that allows the user to specify a portion of the branch name (such as a ticket slug),
   # in which case we should search for the branch to check out.

   local branch_name="$1"

   # Pull latest state from remote
   g sync

   # Check out requested branch locally, and align it with remote if necessary
   g checkout "$branch_name"
   g reset --hard origin/"$branch_name"
}
alias g_get_branch='git_get_branch'

# My wrapper around git, which allows me to define custom git aliases capable of
# performing arbitrary logic, including using other personal utility functions
# without the overhead of asking git to start up a new login shell.
#
# It checks if it recognizes the subcommand as a valid custom alias and executes
# the corresponding function if so. Otherwise, it executes git normally.
function g() {
   local git_subcommand="${1:-}"

   case "$git_subcommand" in
      # Aliases that accept arguments.
      commita|ca)
         git_commita "${@:2}"
         ;;
      commit-diff)
         git_commit_diff "${@:2}"
         ;;
      diff-chunks)
         git_diff_chunks "${@:2}"
         ;;
      ldel-commit)
         git_ldel_commit "${@:2}"
         ;;
      pr-diff)
         git_pr_diff "${@:2}"
         ;;
      squash)
         git_squash "${@:2}"
         ;;
      squashp)
         git_squashp "${@:2}"
         ;;
      delete-b)
         git_delete_b "${@:2}"
         ;;
      get-branch)
         git_get_branch "${@:2}"
         ;;
      # Aliases that do not accept arguments.
      findb)
         git_findb
         ;;
      mainb)
         git_mainb
         ;;
      wt-clean)
         git_wt_clean
         ;;
      sync)
         git_sync
         ;;
      # No alias found, execute git normally.
      *)
         git "${@}"
         ;;
   esac
}
# Set up git completion for my wrapper.
# zsh and bash have different completion systems.
if [ $SHELL = "/bin/zsh" ]; then
   compdef g=git
else
   __git_complete g git
fi

