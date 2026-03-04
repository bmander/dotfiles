Before we merge, look for modularization, deduplication, and elegance anneals to apply.

Focus on:
1. **All code changed on this branch** — use `git diff main...HEAD` to review every change introduced by this branch across the entire repo, not just the current directory
2. **Code tightly coupled with this branch** — files and modules directly imported by or dependent on the changed code

For each area, consider:
- **Modularization**: Can logic be extracted into reusable functions or components?
- **Deduplication**: Is there repeated code that can be consolidated?
- **Elegance**: Are there simplifications, clearer naming, or structural improvements?

Propose concrete changes with file paths and code snippets. Prioritize changes that reduce complexity without altering behavior.

If the review uncovers a larger refactor that is needed but this branch does not significantly entrench, propose creating a GitHub issue for it rather than addressing it here.
