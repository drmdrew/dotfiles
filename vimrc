" drmdrew .vimrc
"
" Configure vim to drmdrew's liking. I find spf13-vim has a few too many
" plugins for my tastes.

" Pre-requisites (for vundle and others)
set nocompatible              " be iMproved, required
filetype off                  " required

" vundle =====
" Remember: to bootstrap bundle:
"   git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
"
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'flazz/vim-colorschemes'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'tpope/vim-fugitive'
Plugin 'git://git.wincent.com/command-t.git'
Plugin 'wookiehangover/jshint.vim'
call vundle#end()            " required
filetype plugin indent on    " required

" keep temporary files out of the way
set backupdir=$HOME/vim.bak//
set directory=$HOME/vim.bak//

" filetypes
filetype plugin indent on

" automatically chdir to the directory of the file being edited (when not diff-ing)
if ! &diff
    set autochdir
endif

" show line-numbers
set number

" appearance: color scheme, etc.
syntax enable
colorscheme solarized
let g:solarized_termcolors=256
set background=dark
set guifont=Menlo\ Regular:h12

" windows/mouse/etc.
set mouse=a
set clipboard=unnamed

" indentation/style
set encoding=utf-8
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab
let g:vim_json_syntax_conceal = 0

" highlight search terms
set hlsearch

" searching/filtering
set wildignore+=node_modules/*,**/node_modules/*,**/bower_components/*,*.min.js

" diff/merge ====
autocmd FilterWritePre * if &diff | setlocal wrap< | endif

" syntastic ====
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" NERDTree ====
"  - NERDTree customizations and mappings
" 1. Map <leader>r for it will highlight (find) the current file
map <leader>r :NERDTreeFind<cr>
map <leader>e :NERDTreeToggle<cr>
" 2. Open NERDTree when VIM is running a GUI
if has('gui_running')
    autocmd VimEnter * NERDTree
endif
" 3. Make sure the cursor doesn't start in NERDTree
autocmd VimEnter * wincmd p
" 4a. Define a function to check if NERDTree is open or active
function! s:isNERDTreeOpen()
  return exists("t:NERDTreeBufName") && (bufwinnr(t:NERDTreeBufName) != -1)
endfunction
" 4b. syncTree will call NERDTreeFind automatically (when NERDTree is running)
function! s:syncTree()
  if &modifiable && s:isNERDTreeOpen() && strlen(expand('%')) > 0 && !&diff
    NERDTreeFind
    wincmd p
  endif
endfunction
autocmd BufRead * call s:syncTree()

" GIT
autocmd BufReadPost fugitive://* set bufhidden=delete

" needed for vim-airline
let g:airline_theme             = 'powerlineish'
let g:airline#extensions#branch#enabled = 1
set laststatus=2