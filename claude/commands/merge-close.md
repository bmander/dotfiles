Merge and clean up the branch for issue $ARGUMENTS:

1. Find the branch name: `git branch | grep $ARGUMENTS`
2. From the main worktree, merge the branch: `git merge <branch-name>`
3. Close the tmux window that was running the worktree: find it with `tmux list-windows` (grep for the issue number), then `tmux kill-window -t <window>`
4. Remove any devcontainer associated with the branch: the container name is `devcontainer-<branch-name>`. Check with `docker container inspect devcontainer-<branch-name>` and if it exists, remove it with `docker rm -f devcontainer-<branch-name>`.
5. If a cloud VM exists for this branch (check `gcloud compute instances describe dc-devcontainer-<branch-name> --project=$DISPATCHDC_GCP_PROJECT --zone=${DISPATCHDC_GCP_ZONE:-us-central1-a} 2>/dev/null`), delete it with `dc-cloud-cleanup <repo_root> <branch-name>`.
6. Remove the worktree (if it exists): `git worktree remove <worktree-path>`
7. Close the issue: `gh issue close $ARGUMENTS`
8. Delete the local branch: `git branch -d <branch-name>`
