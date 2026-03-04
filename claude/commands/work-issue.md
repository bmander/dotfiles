Fetch the GitHub issue details:

```
gh issue view $ARGUMENTS
```

Before starting implementation, check if you are in a git worktree (`git rev-parse --show-toplevel` differs from the main repo). If so, read CLAUDE.md and look for any worktree-specific setup instructions (e.g., creating a venv, installing dependencies). Run those setup commands first.

Then implement the issue. Follow the project conventions in CLAUDE.md. When you are finished, commit your changes with a descriptive message referencing the issue number.
