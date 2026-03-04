Merge the PR and clean up the local branch and worktree for issue $ARGUMENTS:

1. Find the branch name: `git branch | grep $ARGUMENTS`
2. Check if the PR is already merged: `gh pr view <branch-name> --json state`. If already merged, skip to step 4.
3. Merge the PR via GitHub (merge commit, delete remote branch): `gh pr merge <branch-name> --merge --delete-branch`
4. Switch to the main worktree before cleanup
5. Remove the worktree: `git worktree remove <worktree-path>`
6. Delete the local branch: `git branch -d <branch-name>`
7. Pull main to pick up the merged changes: `git pull`
8. Close the tmux window that was running the worktree: find it with `tmux list-windows` (grep for the issue number), then `tmux kill-window -t <window>`
