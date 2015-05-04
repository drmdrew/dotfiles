" setup pathogen (tpope)
execute pathogen#infect()

" keep temporary files out of the way
set backupdir=$HOME/vim.bak//
set directory=$HOME/vim.bak//

" needed for vim-airline
set laststatus=2

" show line-numbers
set number

" color scheme
syntax enable
colorscheme solarized
let g:solarized_termcolors=256
set background=dark
