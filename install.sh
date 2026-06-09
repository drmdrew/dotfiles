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
