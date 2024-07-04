""""""""""""""""""""""""
" Global settings
""""""""""""""""""""""""

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

" Allow moving the cursor via mouse click
set mouse=a

" Enable line numbers
set number

" Add a horizontal and vertical line to the cursor's current position, like a
" crosshairs
set cursorline
set cursorcolumn

set nocompatible


""""""""""""""""""""""""
" Conditional settings
""""""""""""""""""""""""
autocmd FileType elm setlocal tabstop=4 softtabstop=4 shiftwidth=4
autocmd FileType python setlocal tabstop=4 softtabstop=4 shiftwidth=4

" smartindent is good for C-like files, but we want to disable it for other,
" ambiguous filetypes
autocmd FileType conf setlocal nosmartindent
autocmd BufNewFile,BufRead * if &ft == '' | setlocal nosmartindent | endif

