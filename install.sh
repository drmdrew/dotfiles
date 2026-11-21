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

# gpg-touch: YubiKey touch reminder for git commit signing. Symlink the wrapper
# into ~/.local/bin (already on PATH) and point git's gpg.program at it.
mkdir -p ~/.local/bin
ln -v -sf $DOTFILES/bin/gpg-touch ~/.local/bin/gpg-touch
if command -v ykman >/dev/null 2>&1 \
    && ykman openpgp info 2>/dev/null | grep -qiE 'touch policy: *(on|cached|fixed)'; then
    git config --global gpg.program "$HOME/.local/bin/gpg-touch"
else
    git config --global --unset gpg.program 2>/dev/null || true
fi

# pngsaveclaude / pngclauderename: clipboard-image archive + claude-suggested
# descriptive filenames (see bin/pngsaveclaude, bin/pngclauderename).
ln -v -sf $DOTFILES/bin/pngsaveclaude ~/.local/bin/pngsaveclaude
ln -v -sf $DOTFILES/bin/pngclauderename ~/.local/bin/pngclauderename

# Claude Code personal instructions: ~/.claude/CLAUDE.md is a symlink into this repo.
mkdir -p ~/.claude
ln -v -sf $DOTFILES/claude/CLAUDE.md ~/.claude/CLAUDE.md

# mise global config: ~/.config/mise/config.toml is a symlink into this repo.
mkdir -p ~/.config/mise
ln -v -sf $DOTFILES/mise/config.toml ~/.config/mise/config.toml

# Git hooks for this repo only: secret scan on commit via mise (see .githooks/pre-commit).
git -C "$DOTFILES" config core.hooksPath .githooks

# Vim swap/backup directory used by vimrc (backupdir, directory).
mkdir -p ~/.vim.backup
chmod 700 ~/.vim.backup

# Vim colour schemes: ~/.vim/colors is on the runtimepath before packages load, which vimrc needs.
if [ ! -e ~/.vim/colors ]; then
    mkdir -p ~/.vim
    ln -v -s $DOTFILES/vim/colors ~/.vim/colors
else
    echo "~/.vim/colors already exists, skipping"
fi

# Vim plugins: native packages pinned in vim/plugins.txt, installed under ~/.vim/pack.
"$DOTFILES/bin/vim-plugins"
