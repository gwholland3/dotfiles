#------------------------------#
# Bash Functions for Git       #
#------------------------------#

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

   echo $#
   echo "$1"

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
      echo "yes"
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

   local branch_name="$1"

   # Pull latest state from remote
   git sync

   # Check out requested branch locally, and align it with remote if necessary
   git checkout "$branch_name"
   git reset --hard origin/"$branch_name"
}

