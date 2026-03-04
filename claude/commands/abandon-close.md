Abandon and clean up the branch for issue $ARGUMENTS without merging:

1. Find the branch name: `git branch | grep $ARGUMENTS`
2. Remove the worktree: `git worktree remove <worktree-path>`
3. Close the issue: `gh issue close $ARGUMENTS`
4. Force-delete the local branch: `git branch -D <branch-name>`
5. Close the tmux window that was running the worktree: find it with `tmux list-windows` (grep for the issue number), then `tmux kill-window -t <window>`
