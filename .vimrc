scriptencoding utf-8

set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8,sjis

syntax enable

filetype plugin indent on

set autoindent

set clipboard+=unnamed

set cursorline

set foldmethod=indent

"set foldlevelstart=99

set number

set hlsearch

set ignorecase

set incsearch

set tabstop=2

set expandtab

set smartindent

set shiftwidth=2

set undofile
if !isdirectory(expand("$HOME/.vim/undodir"))
  call mkdir(expand("$HOME/.vim/undodir"),"p")
endif
set undodir=$HOME/.vim/undodir

set virtualedit=block

set wildmenu

set runtimepath+=~/src/github.com/sheerun/vim-polyglot

set backspace=2 "set backspace=indent,eol,start と同じ

colorscheme default

packloadall

silent! helptags ALL
