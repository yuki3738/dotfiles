"-----------------------------------
"http://yaoshisi.herokuapp.com/99

set nocompatible               " Be iMproved
if has('vim_starting')
	set runtimepath+=~/.vim/bundle/neobundle.vim/
endif
call neobundle#rc(expand('~/.vim/bundle/'))
"Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'
" Recommended to install
" After install, turn shell ~/.vim/bundle/vimproc, (n,g)make -f your_machines_makefile
NeoBundle 'Shougo/vimproc'
" My Bundles here:
NeoBundle 'scrooloose/nerdtree'
filetype plugin indent on     " Required!
" Installation check.
NeoBundleCheck
autocmd vimenter * NERDTree
syntax on
set number

"-----------------------------------
"http://qiita.com/hokusyu/items/52f15bbf349190e98686

"新しい行のインデントを現在行と同じにする
set autoindent

"クリップボードをMacと連携する
set clipboard=unnamed,autoselect

"タブの代わりに空白文字を指定する
set expandtab

"タブ幅の設定
set tabstop=2

"新しい行を作った時に高度な自動インデントを行う
set smarttab

"http://d.hatena.ne.jp/nzm_o/20100515/1273911397
"オートインデント時にインデントする文字数
set shiftwidth=2

"-----------------------------------
"http://qiita.com/yuku_t/items/0ac33cea18e10f14e185
NeoBundle 'scrooloose/syntastic'
let g:syntastic_mode_map = { 'mode': 'passive',
            \ 'active_filetypes': ['ruby'] }
let g:syntastic_ruby_checkers = ['rubocop']

"-----------------------------------
"https://github.com/cohama/vim-smartinput-endwise
NeoBundle "kana/vim-smartinput"
NeoBundle "cohama/vim-smartinput-endwise"

call smartinput_endwise#define_default_rules()

"-----------------------------------
"http://blogs.yahoo.co.jp/momongamemonga/39861534.html
set backspace=indent,eol,start

"-----------------------------------
"http://blog.livedoor.jp/kumonopanya/archives/51048805.html
"<C-e>でNERDTreeをオンオフ。いつでもどこでも。
"	map <silent> <C-e>   :NERDTreeToggle<CR>
"	lmap <silent> <C-e>  :NERDTreeToggle<CR>
	nmap <silent> <C-e>      :NERDTreeToggle<CR>
	vmap <silent> <C-e> <Esc>:NERDTreeToggle<CR>
	omap <silent> <C-e>      :NERDTreeToggle<CR>
	imap <silent> <C-e> <Esc>:NERDTreeToggle<CR>
	cmap <silent> <C-e> <C-u>:NERDTreeToggle<CR>

"引数なしでvimを開いたらNERDTreeを起動、
"引数ありならNERDTreeは起動しない、引数で渡されたファイルを開く。
"How can I open a NERDTree automatically when vim starts up if no files were specified?
autocmd vimenter * if !argc() | NERDTree | endif

"NERDTreeShowHidden 隠しファイルを表示するか?
"f コマンドの設定値
"0 : 隠しファイルを表示しない。
"1 : 隠しファイルを表示する。
"Values: 0 or 1.
"Default: 0.
"let g:NERDTreeShowHidden=0
let g:NERDTreeShowHidden=1