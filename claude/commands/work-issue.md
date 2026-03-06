Fetch the GitHub issue details:

```
gh issue view $ARGUMENTS
```

Before starting implementation, check if you are in a git worktree
(`git rev-parse --show-toplevel` differs from the main repo). If so,
read CLAUDE.md and look for any worktree-specific setup instructions
(e.g., creating a venv, installing dependencies). Run those setup
commands first.

Then proceed through these phases:

---

## Phase 1: Plan

Enter plan mode and design the implementation. Review the codebase to
understand the relevant code, then produce a concrete plan. Exit plan
mode and wait for the user to approve the plan before continuing.

STOP and wait for user approval before proceeding to Phase 2.

---

## Phase 2: Implement

Implement the plan. Follow the project conventions in CLAUDE.md.
When finished, commit your changes with a descriptive message
referencing the issue number.

Then proceed directly to Phase 3 without waiting.

---

## Phase 3: Test, simplify, and open draft PR

### 3a. Test review
Review the work done so far. Is it both testable and well tested?
If not, add or refactor tests until you are confident in coverage.
Commit any test changes.

### 3b. Simplify
Run `/simplify` to review and clean up the changes.

### 3c. Draft PR
Push the branch and open a draft pull request:
  git push -u origin HEAD
  gh pr create --draft --title "<short title>" --body "<summary>"
Report the PR URL when done.
