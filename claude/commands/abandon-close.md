Abandon and clean up the branch for issue $ARGUMENTS without merging:

1. Find the branch name: first check local branches with `git branch | grep $ARGUMENTS`. If not found, find it from GitHub with `gh pr list --search $ARGUMENTS --json headRefName -q '.[0].headRefName'` or check remote branches with `git branch -r | grep $ARGUMENTS`.
2. If a cloud VM exists for this branch (check `gcloud compute instances describe dc-devcontainer-<branch-name> --project=$DISPATCHDC_GCP_PROJECT --zone=${DISPATCHDC_GCP_ZONE:-us-central1-a} 2>/dev/null`), delete it with `dc-cloud-cleanup <repo_root> <branch-name>`.
3. Remove the worktree (if it exists): `git worktree remove <worktree-path>`
4. Close the issue: `gh issue close $ARGUMENTS`
5. Force-delete the local branch (if it exists): `git branch -D <branch-name>`
6. Delete the remote branch (if it exists): `git push origin --delete <branch-name>`
7. Close the tmux window that was running the worktree: find it with `tmux list-windows` (grep for the issue number), then `tmux kill-window -t <window>`
