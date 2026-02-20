#------------------------------#
# Bash Functions for Git       #
#------------------------------#

# Output the name of the repo's default branch
function git_mainb() {
   # Return if not in a git repo
   git_repo_check

   # If there is a remote called 'origin', return the branch pointed to by its HEAD.
   if git remote | rg origin >/dev/null; then
      basename $(git symbolic-ref --short refs/remotes/origin/HEAD)
      return 0
   fi

   # Check if any common default branches exist, and return the first one found if so.
   for b in main master trunk; do
      if [ -n "$(git branch --list $b)" ]; then
         echo $b
         return 0
      fi
   done

   # Fall back to the default branch used on init as a last resort.
   git config --get init.defaultBranch
}

# Compares the diff of two commits using git range-diff
function git_commit_diff() {
   # Output an error message and exit if there aren't two arguments
   if [ $# -ne 2 ]; then
      echo "Error: this function requires two arguments"
      return 1
   fi

   local commit1="$1"
   local commit2="$2"

   git range-diff "${commit1}"^! "${commit2}"^!
}

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
      <(git show "${first_file_commit}":"${first_file_path}" | sed -n "${first_file_start_line},${first_file_end_line}p") \
      <(git show "${second_file_commit}":"${second_file_path}" | sed -n "${second_file_start_line},${second_file_end_line}p")
}

# Finds which commits have deleted a line based on user-provided line regex. By default,
# only searches three months back to reduce runtime, but this (and other `git log` params)
# can be overridden via additional arguments to this function that are passed to `git log`.
function git_ldel_commit() {
   # Output an error message and exit if there isn't at least one argument
   if [ $# -lt 1 ]; then
      echo "Error: this function requires at least one argument"
      return 1
   fi

   # User-provided regex for the deleted line to search for
   local line_regex="$1"

   # Any additional params to pass to the `git log` command, such as specifying filepaths
   # or requesting a longer search period.
   #
   # Store these as a Bash array so we can expand them into separate words later.
   local git_log_params=("${@:2}")

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
   git log -G"${line_regex}" --since='three months ago' --pretty='tformat:%H' "${git_log_params[@]}" |
      # Check if the read-in line has non-zero length as a secondary condition for entering the while
      # loop, to protect against outputs without a trailing newline.
      while IFS= read -r candidate_commit || [ -n "${candidate_commit}" ]; do
         git show "${candidate_commit}" | rg --quiet "${deletion_regex}.*${line_regex}" && git show "${candidate_commit}" --no-patch
      done
}

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

   git range-diff $(git mainb)@{upstream} "${old_ref}" "${new_ref}"
}

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
   local destination_branch="origin/$(git mainb)"
   if [ $# -gt 0 ]; then
      destination_branch="origin/$1"
      if [ $# -gt 1 ] && [ "$2" == "-l" ]; then
         destination_branch="$1"
      fi
   fi

   # Find the merge-base commit between the feature and destination branches.
   local merge_base_commit
   merge_base_commit="$(git merge-base HEAD "$destination_branch")"

   # If the previous command failed, assume the provided destination branch name was bad
   # and bail out.
   if [ $? -ne 0 ]; then
      echo "Invalid destination branch name: $destination_branch"
      return 1
   fi

   # Reset us back to the merge-base commit, but retain all the changes made on the
   # feature branch so far.
   git reset --soft "$merge_base_commit"
   
   # Grab the commit message from the first commit on the feature branch. This is the message
   # we'll use for our final squashed commit.
   local first_commit_msg="$(git log --reverse --format=%B HEAD..HEAD@{1} | head -n 1)"

   # Create a new, squashed commit with all the changes on the feature branch.
   git commit -m "$first_commit_msg"
}

# Attempt to force delete the specified branch name from both remote and local.
function git_delete_b() {
   # Return if not in a git repo
   git_repo_check

   # Return if there are local changes
   git_wt_clean_check

   local branch_to_delete="$1"

   # If we currently have to to-be-deleted branch checked out,
   # first check out the main branch instead
   local current_branch="$(git rev-parse --abbrev-ref HEAD)"
   if [ "$current_branch" == "$branch_to_delete" ]; then
      echo "Branch to be deleted is currently checked out, switching to repository main branch"
      git checkout "$(git mainb)"
   fi

   # First attempt to delete the branch on the remote, then
   # try to delete it locally. If either branch doesn't exist,
   # git already has its own helpful error messages.
   git push -d origin "$branch_to_delete"
   git branch -D "$branch_to_delete"
}

# Check if the worktree is clean. Exit code 0 if there are no local changes, 1 otherwise.
function git_wt_clean() {
   # Return if not in a git repo
   git_repo_check
   
   # The "short" output of `git status` should contain nothing if the worktree is clean
   [ -z "$(git status -s)" ]
}

# Checkout the main branch and updated it from remote
function git_now() {
   # Return if not in a git repo
   git_repo_check

   # Return if there are local changes
   git_wt_clean_check

   git checkout $(git mainb)
   git pull -p
}

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
      git stash push -u
   fi

   # Checkout the repo's default branch, fetch from remote, and update the branch
   git checkout "$(git mainb)"
   git pull -p

   # Return to the original branch
   git checkout -

   if [ "${wt_clean}" -ne 0 ]; then
      # Restore any uncommitted changes on the original branch
      git stash pop
   fi
}

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
   git sync

   # Check out requested branch locally, and align it with remote if necessary
   git checkout "$branch_name"
   git reset --hard origin/"$branch_name"
}

