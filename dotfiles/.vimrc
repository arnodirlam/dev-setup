" Plug Required Block and plugins
set nocompatible
filetype off
call plug#begin('~/.vim/bundle')
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'                   " loads all programming languages
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-endwise'                      " auto-add `end` statements
Plug 'vim-airline/vim-airline'                " Status bar
Plug 'vim-airline/vim-airline-themes'         " Status bar themes
Plug 'scrooloose/nerdtree'                    " Tree file explorer
Plug 'Xuyuanp/nerdtree-git-plugin'            " Git markers for Nerdtree
Plug 'neomake/neomake'                        " Runs code checks automatically
Plug 'tpope/vim-rails', { 'for': 'ruby' }
Plug 'tpope/vim-endwise', { 'for': 'ruby' }
Plug 'flazz/vim-colorschemes'
Plug 'xolox/vim-colorscheme-switcher'
Plug 'xolox/vim-misc'
Plug 'elixir-lang/vim-elixir'
Plug 'slashmili/alchemist.vim'
" Plug 'Valloric/YouCompleteMe', { 'do': './install.py' }
call plug#end()
syntax on
filetype plugin indent on
" End of Plug Required Block and plugins

let mapleader = ',' " define map leader
" colorscheme dark-ruby
" colorscheme monokai-chris
" colorscheme benlight
" colorscheme birds-of-paradise
" colorscheme flatland
" colorscheme kruby
colorscheme lucid
" colorscheme obsidian

let g:airline_theme='wombat'
let g:airline_powerline_fonts = 0
""seperators
let g:airline_left_sep = ''
let g:airline_right_sep = ''
"modes
let g:airline_section_b=""
let g:airline_section_x=""
let g:airline_section_y=""

let g:polyglot_disabled = ['elixir']

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Vim variables
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set autoindent " Auto indent
set smartindent "Smart indet
set smarttab
set softtabstop=2 " indentation
set tabstop=2 " indentation
set shiftwidth=2 " indentation
set expandtab " convert tabs to spaces
set number " enable line numbers
set ttyscroll=3 " speed up scrolling
set ttyfast " Optimize for fast terminal connections
set lazyredraw " to avoid scrolling problems
set backspace=indent,eol,start  " Enable backspace in most situations


"""""""""""""""""""
" => Key bindings "
"""""""""""""""""""
set pastetoggle=<F9>
map <C-n> :NERDTreeToggle<CR>


"""""""""""""""
" => Triggers "
"""""""""""""""
autocmd! BufWritePost * Neomake

augroup elixir
  autocmd!
  autocmd FileType elixir
    \ let b:endwise_addition = 'end' |
    \ let b:endwise_words = ''
      \ . 'def,'
      \ . 'defmodule,'
      \ . 'case,'
      \ . 'cond,'
      \ . 'bc,'
      \ . 'lc,'
      \ . 'inlist,'
      \ . 'inbits,'
      \ . 'if,'
      \ . 'unless,'
      \ . 'try,'
      \ . 'receive,'
      \ . 'function,'
      \ . 'fn'
      \ |
    \ let b:endwise_pattern = ''
      \ . '^\s*\zs\%('
        \ . 'def\|'
        \ . 'defmodule\|'
        \ . 'case\|'
        \ . 'cond\|'
        \ . 'bc\|'
        \ . 'lc\|'
        \ . 'inlist\|'
        \ . 'inbits\|'
        \ . 'if\|'
        \ . 'unless\|'
        \ . 'try\|'
        \ . 'receive\|'
        \ . 'function\|'
        \ . 'fn'
      \ . '\)\>\%(.*[^:]\<end\>\)\@!'
      \ |
    \ let b:endwise_syngroups = ''
      \ . 'elixirDefine,'
      \ . 'elixirModuleDefine,'
      \ . 'elixirKeyword'
augroup END
