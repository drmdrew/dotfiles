#!/bin/bash
#
# install.sh - Creates symbolic links for dotfiles in the user's 
#              home directory.
#
DOTFILES=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)

rm ~/.vimrc
ln -v -s $DOTFILES/vimrc ~/.vimrc

