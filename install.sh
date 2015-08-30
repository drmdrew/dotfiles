#!/bin/sh
#
# install.sh - Creates symbolic links for dotfiles in the user's 
#              home directory.
#

DOTFILES=$(dirname $0)

ln -v -s $DOTFILES/vimrc ~/.vimrc

