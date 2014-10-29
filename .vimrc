"""""""""""""""""""""""""""""""
" 挙動を vi 互換ではなく、Vim のデフォルト設定にする
"""""""""""""""""""""""""""""""
set nocompatible

"""""""""""""""""""""""""""""""
" 一旦ファイルタイプ関連を無効化する
"""""""""""""""""""""""""""""""
filetype off

"""""""""""""""""""""""""""""""
" プラグインのセットアップ
"""""""""""""""""""""""""""""""
if has('vim_starting')
	set runtimepath+=~/.vim/bundle/neobundle.vim/
endif
call neobundle#rc(expand('~/.vim/bundle/'))
"Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'

" My Bundles here:
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'tpope/vim-rails'
NeoBundle 'Shougo/neosnippet'
NeoBundle 'Shougo/neocomplete'
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'terryma/vim-multiple-cursors'
NeoBundle 'nathanaelkane/vim-indent-guides'
NeoBundle 'vim-scripts/AnsiEsc.vim' " ログファイルを色づけしてくれる
NeoBundle 'bronson/vim-trailing-whitespace' " 行末の半角スペースを可視化
NeoBundle 'Shougo/vimproc', {
      \ 'build' : {
      \     'windows' : 'tools\\update-dll-mingw',
      \     'cygwin' : 'make -f make_cygwin.mak',
      \     'mac' : 'make -f make_mac.mak',
      \     'unix' : 'make -f make_unix.mak',
      \    },
      \ }

filetype plugin indent on     " Required!
" Installation check.
NeoBundleCheck
autocmd vimenter * NERDTree


""""""""""""""""""""""""""""""
" 各種オプションの設定
""""""""""""""""""""""""""""""
" 行番号を表示する
set number

"新しい行のインデントを現在行と同じにする
set autoindent

"クリップボードをMacと連携する
set clipboard+=unnamed,autoselect

"タブの代わりに空白文字を指定する
set expandtab

"タブ幅の設定
set tabstop=2

"新しい行を作った時に高度な自動インデントを行う
set smarttab

"http://d.hatena.ne.jp/nzm_o/20100515/1273911397
"オートインデント時にインデントする文字数
set shiftwidth=2

"http://blogs.yahoo.co.jp/momongamemonga/39861534.html
set backspace=indent,eol,start

" カーソルが何行目の何列目に置かれているかを表示する
set ruler

" エディタウィンドウの末尾から2行目にステータスラインを常時表示させる
set laststatus=2

" コマンドラインモードで<Tab>キーによるファイル名補完を有効にする
set wildmenu

" 小文字のみで検索したときに大文字小文字を無視する
set smartcase

" 検索ワードの最初の文字を入力した時点で検索を開始する
set incsearch

" 構文毎に文字色を変化させる
syntax on

"検索結果をハイライトする
set hlsearch

"保存時に末尾の改行コードを取り除く
set binary noeol

"インデントの際、タブ文字ではなく、半角スペースが挿入される
set expandtab

" ファイルが更新されたら自動的にリロード
set autoread 


""""""""""""""""""""""""""""""
"neocompleteの設定
""""""""""""""""""""""""""""""
let g:neocomplete#enable_at_startup = 1
if !exists('g:neocomplete#force_omni_input_patterns')
    let g:neocomplete#force_omni_input_patterns = {}
  endif
  let g:neocomplete#force_omni_input_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'


""""""""""""""""""""""""""""""
"scrooloose/syntasticの設定
"http://qiita.com/yuku_t/items/0ac33cea18e10f14e185
""""""""""""""""""""""""""""""
let g:syntastic_mode_map = { 'mode': 'passive',
            \ 'active_filetypes': ['ruby'] }
let g:syntastic_ruby_checkers = ['rubocop']

""""""""""""""""""""""""""""""
" NERDTreeの設定
"""""""""""""""""""""""""""""

"<C-e>でNERDTreeをオンオフ。いつでもどこでも。
"http://blog.livedoor.jp/kumonopanya/archives/51048805.html
	nmap <silent> <C-e>      :NERDTreeToggle<CR>
	vmap <silent> <C-e> <Esc>:NERDTreeToggle<CR>
	omap <silent> <C-e>      :NERDTreeToggle<CR>
	imap <silent> <C-e> <Esc>:NERDTreeToggle<CR>
	cmap <silent> <C-e> <C-u>:NERDTreeToggle<CR>


"引数なしでvimを開いたらNERDTreeを起動、
"引数ありならNERDTreeは起動しない、引数で渡されたファイルを開く。
"https://github.com/scrooloose/nerdtree
"How can I open a NERDTree automatically when vim starts up if no files were specified?
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

"NERDTreeShowHidden 隠しファイルを表示するか?
"f コマンドの設定値
"0 : 隠しファイルを表示しない。
"1 : 隠しファイルを表示する。
"Values: 0 or 1.
"Default: 0.
let g:NERDTreeShowHidden=1

"カーソルラインをハイライト表示する。
let g:NERDTreeHighlightCursorline=1

"ブックマークや、ヘルプのショートカットをメニューに表示する。
let g:NERDTreeMinimalUI=1


""""""""""""""""""""""""""""""
" vim-indent-guidesの設定
" vimを立ち上げたときに、自動的にvim-indent-guidesをオンにする
" (今のitermのテーマに合わなかった。)
""""""""""""""""""""""""""""""
"let g:indent_guides_enable_on_vim_startup = 1

""""""""""""""""""""""""""""""
" 全角スペースの表示
" http://inari.hatenablog.com/entry/2014/05/05/231307
""""""""""""""""""""""""""""""
function! ZenkakuSpace()
    highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=darkgray
endfunction

if has('syntax')
    augroup ZenkakuSpace
        autocmd!
        autocmd ColorScheme * call ZenkakuSpace()
        autocmd VimEnter,WinEnter,BufRead * let w:m1=matchadd('ZenkakuSpace', '　')
    augroup END
    call ZenkakuSpace()
endif


""""""""""""""""""""""""""""""
" 挿入モード時、ステータスラインの色を変更
" https://sites.google.com/site/fudist/Home/vim-nihongo-ban/-vimrc-sample
""""""""""""""""""""""""""""""
let g:hi_insert = 'highlight StatusLine guifg=darkblue guibg=darkyellow gui=none ctermfg=blue ctermbg=yellow cterm=none'

if has('syntax')
  augroup InsertHook
    autocmd!
    autocmd InsertEnter * call s:StatusLine('Enter')
    autocmd InsertLeave * call s:StatusLine('Leave')
  augroup END
endif

let s:slhlcmd = ''
function! s:StatusLine(mode)
  if a:mode == 'Enter'
    silent! let s:slhlcmd = 'highlight ' . s:GetHighlight('StatusLine')
    silent exec g:hi_insert
  else
    highlight clear StatusLine
    silent exec s:slhlcmd
  endif
endfunction

function! s:GetHighlight(hi)
  redir => hl
  exec 'highlight '.a:hi
  redir END
  let hl = substitute(hl, '[\r\n]', '', 'g')
  let hl = substitute(hl, 'xxx', '', '')
  return hl
endfunction


""""""""""""""""""""""""""""""
" 最後のカーソル位置を復元する
""""""""""""""""""""""""""""""
if has("autocmd")
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif
endif


""""""""""""""""""""""""""""""
" 自動的に閉じ括弧を入力
" (20140908 微妙だったのでコメントアウト)
""""""""""""""""""""""""""""""
"imap { {}<LEFT>
"imap [ []<LEFT>
"imap ( ()<LEFT>


""""""""""""""""""""""""""""""
" filetypeの自動検出(最後の方に書いた方がいいらしい)
""""""""""""""""""""""""""""""
filetype on

