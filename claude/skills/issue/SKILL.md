---
name: issue
description: Create a GitHub issue
allowed-tools: Bash, Read, Glob, Grep
---

Create a GitHub issue using the `gh` CLI.

Arguments are passed as: `/issue <description>`. If no description is provided, ask the user for one.

Investigate the codebase if appropriate to write a well-informed issue body.

Generate a short, concise title (under 70 characters) from the description automatically.

Use `gh issue create --title "<title>" --body "<body>"` to create the issue.

When done, return only the issue number like "Created issue #40".
