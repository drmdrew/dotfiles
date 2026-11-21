" drmdrew .vimrc
"
" Configure vim to drmdrew's liking. I find spf13-vim has a few too many
" plugins for my tastes.

"if !empty($VIM_PROFILE)
"  execute 'profile start /tmp/vim-profile-' . strftime('%H%M%S') . '.log'
"  profile func *
"  profile file *
"endif


set nocompatible              " be iMproved

" Do not apply settings embedded in opened files or read project vimrc files
set nomodeline
set modelines=0
set nomodelineexpr
set noexrc

" No swap or undo copies of secret-bearing files
autocmd BufNewFile,BufReadPre *.env,.env.*,*.pem,*.key,id_rsa*,id_ed25519*,*credentials*,*secret*,*kubeconfig* setlocal noswapfile noundofile

" vim/neovim compatability
if has('nvim')
    set runtimepath^=~/.vim runtimepath+=~/.vim/after
    let &packpath = &runtimepath
endif

" ==========================================
" Asynchronous Lint Engine (ALE) Settings
" ==========================================
let g:ale_enabled = 1

" Run only the linters listed here; filetypes not listed get none.
" This ALE version ships a 'tombi' recipe but no 'taplo' recipe, so naming
" 'taplo' here produced an empty enabled-linter set and aborted linting.
let g:ale_linters_explicit = 1
let g:ale_linters = {
\   'sh': ['shellcheck'],
\   'toml': ['tombi'],
\}

" Prefer global executables over project-local ones (node_modules/.bin, etc.).
let g:ale_use_global_executables = 1

" Lint on save only, so opening or editing a file in an untrusted repo runs nothing.
let g:ale_lint_on_enter = 0
let g:ale_lint_on_filetype_changed = 0
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_save = 1

" Customize the indicators displayed in the left-hand gutter column
let g:ale_sign_error = '❌'
let g:ale_sign_warning = '⚠️'

" keep temporary files out of the way
set backupdir=$HOME/.vim.backup/
set directory=$HOME/.vim.backup/

" filetypes
filetype plugin indent on

" automatically chdir to the directory of the file being edited (when not diff-ing)
if ! &diff
    set autochdir
endif

" auto-reload files when changed outside vim (especially for ~/notes)
set autoread
" Update time for CursorHold events (2 seconds for more responsive auto-reload)
set updatetime=2000
" Check for file changes when vim gains focus or cursor moves
au FocusGained,BufEnter,CursorHold,CursorHoldI * if expand('%') != '' | checktime | endif
" Also check periodically for files in ~/notes
au CursorHold * if getcwd() =~ '/notes' && expand('%') != '' | checktime | endif

" show line-numbers
set number

" visualize (list) whitespace
nmap <leader>l :set list!<CR>
set listchars=eol:⏎,tab:▸\ ,trail:·,nbsp:⎵
highlight NonText guifg=#4a4a59
highlight SpecialKey guifg=#4a4a59
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" windows/mouse/etc.
set mouse=a
if has('mac') || has('macunix')
  set clipboard=unnamed
else
  set clipboard=unnamedplus
endif
let g:buftabline_numbers=1

" navigation / keyboard mappings
nnoremap <C-N> :bnext<CR>

" indentation/style
set encoding=utf-8
set tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
let g:vim_json_syntax_conceal = 0

" filetype specific styles
autocmd Filetype sh setlocal ts=2 sts=2 sw=2
autocmd FileType markdown setlocal spell

" markdown: paste a clipboard screenshot into a per-ISO-week images/ dir (requires pngpaste)
function! s:PasteImage() abort
  let l:week = strftime('%G-W%V')
  let l:dir  = expand('%:p:h') . '/images/' . l:week
  if !isdirectory(l:dir) | call mkdir(l:dir, 'p') | endif
  let l:name = strftime('%Y%m%d-%H%M%S') . '.png'
  call system('pngpaste ' . shellescape(l:dir . '/' . l:name))
  if v:shell_error != 0
    echohl ErrorMsg | echom 'pngpaste: no image on clipboard' | echohl None
    return
  endif
  call append(line('.'), '![](images/' . l:week . '/' . l:name . ')')
  normal! j
endfunction
command! PasteImage call s:PasteImage()
autocmd FileType markdown nnoremap <buffer> <leader>p :PasteImage<CR>

" :Claude <instruction> asks claude-vi (read-only Claude) and puts the reply in the buffer:
" replaces the selected/ranged lines, or inserts below the cursor line when no range is given.
function! s:Claude(line1, line2, range, instruction) abort
  let l:args = ['claude-vi', '--file', expand('%:p'), '--ft', &filetype,
        \ '--line1', a:line1, '--line2', a:line2, '--range', a:range, '--', a:instruction]
  echo 'claude-vi: working...' | redraw
  let l:errfile = tempname()
  " stop at the commit-editor scissors line so the -v diff is never sent; cap long buffers
  let l:cut = search('^# -\+ >8 -\+$', 'nw')
  let l:last = min([l:cut > 0 ? l:cut - 1 : line('$'), 2000])
  let l:out = system(join(map(l:args, 'shellescape(v:val)'), ' ') . ' 2>' . shellescape(l:errfile), join(getline(1, l:last), "\n") . "\n")
  let l:status = v:shell_error
  let l:err = filereadable(l:errfile) ? join(readfile(l:errfile, '', 3), ' | ') : ''
  call delete(l:errfile)
  if l:status != 0
    echohl ErrorMsg | echom 'claude-vi failed (exit ' . l:status . '): ' . (l:err !=# '' ? l:err : l:out !=# '' ? l:out : 'no output') | echohl None
    return
  endif
  let l:lines = split(l:out, "\n")
  if a:range > 0
    execute a:line1 . ',' . a:line2 . 'delete _'
    call append(a:line1 - 1, l:lines)
  else
    call append(a:line1, l:lines)
  endif
endfunction
command! -range -nargs=+ Claude call s:Claude(<line1>, <line2>, <range>, <q-args>)

" highlight search terms
set hlsearch

" searching/filtering
set wildignore+=node_modules/*,**/node_modules/*,**/bower_components/*,*.min.js

" diff/merge ====
autocmd FilterWritePre * if &diff | setlocal wrap< | endif

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

" golang preferences
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_interfaces = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

set autowrite
autocmd FileType go nmap <leader>b  <Plug>(go-build)
autocmd FileType go nmap <leader>r  <Plug>(go-run)
autocmd FileType go nmap <leader>t  <Plug>(go-test)
autocmd FileType go nmap <Leader>c <Plug>(go-coverage-toggle)

let g:go_list_type = "quickfix"

"" appearance: color scheme, etc.
syntax enable
set termguicolors
set guifont=Menlo\ Regular:h12
"" highlight Visual ctermbg=LightBlue ctermfg=Grey
colorscheme zenburn


