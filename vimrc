" setup pathogen (tpope)
execute pathogen#infect()

" keep temporary files out of the way
set backupdir=$HOME/vim.bak//
set directory=$HOME/vim.bak//

" automatically set the directory of the file being edited
set autochdir

" show line-numbers
set number

" color scheme
syntax enable
colorscheme solarized
let g:solarized_termcolors=256
set background=dark

" windows/mouse/etc.
set mouse=a

" indentation/style
set encoding=utf-8
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab
let g:vim_json_syntax_conceal = 0

" highlight search terms
set hlsearch

" NERDTree ================================================================
"  - NERDTree customizations and mappings
" 1. Map <leader>r for it will highlight (find) the current file
map <leader>r :NERDTreeFind<cr>
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
autocmd BufEnter * call s:syncTree()

" GIT
autocmd BufReadPost fugitive://* set bufhidden=delete

" needed for vim-airline
let g:airline_theme             = 'powerlineish'
let g:airline#extensions#branch#enabled = 1
set laststatus=2
