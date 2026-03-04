#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

link_file() {
    local src="$1" dest="$2"
    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -e "$dest" ]; then
        echo "Warning: $dest exists and is not a symlink, skipping"
        return
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "Linked $(basename "$dest")"
}

# Symlink bin/ scripts to ~/bin/
for script in "$DOTFILES_DIR"/bin/*; do
    [ -f "$script" ] || continue
    link_file "$script" "$HOME/bin/$(basename "$script")"
done

# Symlink Claude Code settings
link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"

# Symlink Claude Code commands
for cmd in "$DOTFILES_DIR"/claude/commands/*.md; do
    [ -f "$cmd" ] || continue
    link_file "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
done

# Symlink Claude Code skills
for skill_dir in "$DOTFILES_DIR"/claude/skills/*/; do
    [ -d "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"
    link_file "$skill_dir" "$HOME/.claude/skills/$name"
done

echo "Done. Make sure ~/bin is on your PATH."
