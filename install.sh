#!/bin/bash
#
# install.sh - Creates symbolic links for dotfiles in the user's 
#              home directory.
#
DOTFILES=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)

ln -v -sf $DOTFILES/vimrc ~/.vimrc
ln -v -sf $DOTFILES/zshrc ~/.zshrc

# Neovim compatibility symlinks
mkdir -p ~/.config/nvim

if [ ! -e ~/.config/nvim/init.vim ]; then
    ln -v -s ~/.vimrc ~/.config/nvim/init.vim
else
    echo "~/.config/nvim/init.vim already exists, skipping"
fi

if [ ! -e ~/.config/nvim/vimfiles ]; then
    ln -v -s ~/.vim ~/.config/nvim/vimfiles
else
    echo "~/.config/nvim/vimfiles already exists, skipping"
fi

# --- Coding agents -----------------------------------------------------------
#
# agents/  : tool-agnostic AGENTS.md + Agent Skills (SKILL.md folders)
# claude/  : Claude Code-specific files
#
# safe_ln SRC DEST: like `ln -sfn`, but skips (with a warning) when DEST is
# a real directory, where ln would otherwise create the link *inside* it.
safe_ln() {
    if [ -d "$2" ] && [ ! -L "$2" ]; then
        echo "$2 is a real directory, skipping (move it aside and re-run)"
    else
        ln -v -sfn "$1" "$2"
    fi
}

mkdir -p ~/.agents ~/.claude/skills
safe_ln $DOTFILES/agents/AGENTS.md ~/.agents/AGENTS.md
safe_ln $DOTFILES/agents/skills    ~/.agents/skills

safe_ln $DOTFILES/claude/CLAUDE.md     ~/.claude/CLAUDE.md
safe_ln $DOTFILES/claude/settings.json ~/.claude/settings.json

# ~/.claude/skills also holds claude.ai-synced skills, so link each skill
# individually rather than replacing the directory.
for skill in $DOTFILES/agents/skills/*/; do
    [ -d "$skill" ] || continue
    safe_ln "${skill%/}" ~/.claude/skills/$(basename "$skill")
done

# Build skills that ship a renderer or other tooling (see mise.toml).
if command -v mise >/dev/null; then
    mise trust --quiet "$DOTFILES/mise.toml"
    mise -C "$DOTFILES" run skills:setup \
        || echo "warning: some skills failed to build; fix and run: mise run skills:setup" >&2
else
    echo "warning: mise not found; install it, then run: mise run skills:setup" >&2
fi
