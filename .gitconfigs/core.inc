# This is all my core configuration, which I would want to apply no matter what my setup.

[core]
   # Do not automatically convert line endings in the working directory to CRLF
	autocrlf = input
[color]
   # Use color when outputting to the terminal
	ui = auto
[alias]
   # Very pretty logging output
	lg = log --graph --branches --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative --author-date-order

   # Show the last commit that touched a file, even if that file has been deleted (relative to HEAD)
	fdel-commit = log -1 --

   # Alias for checking if the current working directory is in a git repo. This command should output
   # the typical git error message if not in a repo. Otherwise, it outputs nothing. Its exit code also
   # corresponds with whether it's in a git repo.
   in-repo = rev-parse

   # Force push, but only if the remote branch hasn't been updated since the last fetch and its tip is still contained in the overriding branch
	pushfl = push --force-with-lease --force-if-includes

   # Amend most recent commit with current changes and keep the same commit message
   fixup = commit --amend --no-edit

   # Outputs the name of the branch that is currently checked out, or nothing if HEAD is not pointing to a branch
   thisb = branch --show-current

   # Detach at the current commit
   dt = checkout -d HEAD

   # Check out the previous commit that HEAD was pointing to
   back = checkout -

   # Simple shorthand aliases.
   rl = reflog

   #exec =  "!$@ #"  ; Lol. See additional options below:
   #exec2 = "!$@;:"
   #exec3 = "!:;"

   ###############################################################
   # SHELL FUNCTIONS 
   #
   # I have to request git to launch a login shell in
   # order for these functions to be available for use
   # as a git alias.
   #
   # Check the corresponding documentation from the function
   # definitions for more about what these do.
   ###############################################################

   # Functions that don't require arguments
   mainb             = "!bash -l -c 'git_mainb'"
   go-main           = "!bash -l -c 'git_go_main'"
   findb             = "!bash -l -c 'git_findb'"
   now               = "!bash -l -c 'git_now'"
   sync              = "!bash -l -c 'git_sync'"
   syncm             = "!bash -l -c 'git_syncm'"
   wt-clean          = "!bash -l -c 'git_wt_clean'"
   irebase-self      = "!bash -l -c 'git_irebase_self'"
   auto-prune        = "!bash -l -c 'git_auto_prune'"

   # This strange way of invoking these Bash functions allows them to receive arguments
   get-branch        = "!bash -l -c '\"$0\" \"$@\"' git_get_branch"
   delete-b          = "!bash -l -c '\"$0\" \"$@\"' git_delete_b"
   squash            = "!bash -l -c '\"$0\" \"$@\"' git_squash"
   pr-diff           = "!bash -l -c '\"$0\" \"$@\"' git_pr_diff"
   ldel-commit       = "!bash -l -c '\"$0\" \"$@\"' git_ldel_commit"
   diff-chunks       = "!bash -l -c '\"$0\" \"$@\"' git_diff_chunks"
   commit-diff       = "!bash -l -c '\"$0\" \"$@\"' git_commit_diff"
   commita           = "!bash -l -c '\"$0\" \"$@\"' git_commita"
   ca                = "!bash -l -c '\"$0\" \"$@\"' git_commita"
   contains          = "!bash -l -c '\"$0\" \"$@\"' git_contains"
   bisect-lrun       = "!bash -l -c '\"$0\" \"$@\"' git_bisect_lrun"

[pull]
   # When running git pull, do not rebase current branch on top of upstream branch should it have diverged
	rebase = false
[init]
   # Override the default branch name when initializing a new Git repository
	defaultBranch = main
[grep]
   # Always show line numbers in output of git grep
	lineNumber = true
[push]
   # Automatically set up an upstream tracking branch when running `git push` on a local-only branch
	autoSetupRemote = true

