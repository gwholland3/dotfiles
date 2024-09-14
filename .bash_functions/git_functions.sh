#------------------------------#
# Bash Functions for Git       #
#------------------------------#

# Check if the worktree is clean. Exit code 0 if there are no local changes, 1 otherwise.
function git_wt_clean() {
   # Return if not in a git repo
   git_repo_check
   
   # The "short" output of `git status` should contain nothing if the worktree is clean
   [ -z "$(git status -s)" ]
}
#
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

