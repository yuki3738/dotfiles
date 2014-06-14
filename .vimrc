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
" After install, turn shell ~/.vim/bundle/vimroc,rkdown'
"  Bundle 'suan/vim-instant-markdown'(n,g)make -f your_machines_makefile
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

"カーソルラインをハイライト表示する。
let g:NERDTreeHighlightCursorline=1

"ブックマークや、ヘルプのショートカットをメニューに表示する。
let g:NERDTreeMinimalUI=1
"-----------------------------------
"http://blog.remora.cx/2010/12/vim-ref-with-unite.html
NeoBundle 'Shougo/unite.vim'

" 入力モードで開始する
let g:unite_enable_start_insert=1
" バッファ一覧
noremap <C-P> :Unite buffer<CR>
" ファイル一覧
noremap <C-N> :Unite -buffer-name=file file<CR>
" 最近使ったファイルの一覧
noremap <C-Z> :Unite file_mru<CR>
 
" ウィンドウを分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-J> unite#do_action('split')
au FileType unite inoremap <silent> <buffer> <expr> <C-J> unite#do_action('split')
" ウィンドウを縦に分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-K> unite#do_action('vsplit')
au FileType unite inoremap <silent> <buffer> <expr> <C-K> unite#do_action('vsplit')
" ESCキーを2回押すと終了する
au FileType unite nnoremap <silent> <buffer> <ESC><ESC> :q<CR>
au FileType unite inoremap <silent> <buffer> <ESC><ESC> <ESC>:q<CR>
" 初期設定関数を起動する
au FileType unite call s:unite_my_settings()
    function! s:unite_my_settings()
    " Overwrite settings.
endfunction
 
" 様々なショートカット
call unite#custom#substitute('file', '\$\w\+', '\=eval(submatch(0))', 200)
call unite#custom#substitute('file', '^@@', '\=fnamemodify(expand("#"), ":p:h")."/"', 2)
call unite#custom#substitute('file', '^@', '\=getcwd()."/*"', 1)
call unite#custom#substitute('file', '^;r', '\=$VIMRUNTIME."/"')
call unite#custom#substitute('file', '^\~', escape($HOME, '\'), -2)
call unite#custom#substitute('file', '\\\@<! ', '\\ ', -20)
call unite#custom#substitute('file', '\\ \@!', '/', -30)
 
if has('win32') || has('win64')
    call unite#custom#substitute('file', '^;p', 'C:/Program Files/')
    call unite#custom#substitute('file', '^;v', '~/vimfiles/')
else
    call unite#custom#substitute('file', '^;v', '~/.vim/')
endif
"-----------------------------------
"http://kaworu.jpn.org/kaworu/2010-11-20-1.php
set hlsearch

