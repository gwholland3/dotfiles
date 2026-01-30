""""""""""""""""""""""""
" Global settings
""""""""""""""""""""""""

" Load optional plugins
" We prefix these commands with `silent!` so that they don't output an error
" message if a plugin happens to not exist on particular system.
"
" The `comment` plugin enables commenting and uncommenting lines quickly.
silent! packadd comment

" Set the default width of a tab to N spaces
set tabstop=3
set softtabstop=3
set shiftwidth=3

" Whenever a tab character is inserted, expand it into multiple spaces instead
set expandtab

" Enable automatic filetype detection, apply filetype-specific indentation
" rules, and use filetype-specific plugins
filetype plugin indent on

syntax on
set autoindent
set smartindent
set nowrap

" Highlight search matches, both while and after typing
set hlsearch
set incsearch

" Allow moving the cursor via mouse click
set mouse=a

" Enable line numbers
set number

" Add a horizontal and vertical line to the cursor's current position, like a
" crosshairs
set cursorline
set cursorcolumn

set nocompatible

" Dynamically replace '%%' with '%:h' in Ex commands
cnoremap <expr> %%  getcmdtype() == ':' ? expand('%:h').'/' : '%%'


""""""""""""""""""""""""
" Conditional settings
""""""""""""""""""""""""
autocmd FileType elm setlocal tabstop=4 softtabstop=4 shiftwidth=4
autocmd FileType python setlocal tabstop=4 softtabstop=4 shiftwidth=4

" smartindent is good for C-like files, but we want to disable it for other,
" ambiguous filetypes
autocmd FileType conf setlocal nosmartindent
autocmd BufNewFile,BufRead * if &ft == '' | setlocal nosmartindent | endif

" Associate `.inc` files (my gitconfig include files) with the `gitconfig`
" filetype for proper syntax highlighting
autocmd BufNewFile,BufRead *.inc set filetype=gitconfig

