Merge the PR and clean up the local branch and worktree for issue $ARGUMENTS:

1. Find the branch name: first check local branches with `git branch | grep $ARGUMENTS`. If not found, find it from GitHub with `gh pr list --search $ARGUMENTS --json headRefName -q '.[0].headRefName'`.
2. Check if the PR is already merged: `gh pr view <branch-name> --json state`. If already merged, skip to step 4.
3. Merge the PR via GitHub (merge commit, delete remote branch): `gh pr merge <branch-name> --merge --delete-branch`
4. Switch to the main worktree before cleanup
5. If a cloud VM exists for this branch (check `gcloud compute instances describe dc-devcontainer-<branch-name> --project=$DISPATCHDC_GCP_PROJECT --zone=${DISPATCHDC_GCP_ZONE:-us-central1-a} 2>/dev/null`), delete it with `dc-cloud-cleanup <repo_root> <branch-name>`.
6. Remove the worktree (if it exists): `rm -rf <worktree-path> && git worktree prune`
7. Pull main to pick up the merged changes: `git pull`
8. Delete the local branch (if it exists): `git branch -d <branch-name>`
9. Close the tmux window that was running the worktree: find it with `tmux list-windows` (grep for the issue number), then `tmux kill-window -t <window>`
