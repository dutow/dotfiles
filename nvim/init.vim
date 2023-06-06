set nocompatible

set showmatch
set ignorecase
set hlsearch
set incsearch

set number
set cc=120
set cursorline
set cursorcolumn

syntax on
filetype plugin on
filetype plugin indent on
set expandtab
set autoindent

set mouse=v
set mouse=a
set clipboard=unnamedplus

set ttyfast
set backupdir=~/.cache/vim

let mapleader ="\<Space>"

set termguicolors

lua require('plugins')

" Why these do not work in lua?
nnoremap <silent>    <C-PageUp> <Cmd>BufferPrevious<CR>
nnoremap <silent>    <C-PageDown> <Cmd>BufferNext<CR>
nnoremap <silent>    <C-F12> <Cmd>BufferClose<CR>
nnoremap <silent> <leader>f :Format<CR>
nnoremap <silent> <leader>F :FormatWrite<CR>
