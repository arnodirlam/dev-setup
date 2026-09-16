if exists('g:vscode')
    " VSCode extension
    set clipboard=unnamedplus
else
  " Install vim-plug if missing
  if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
    silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
      \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  endif

  " Specify a directory for plugins (for Neovim: ~/.local/share/nvim/plugged)
  call plug#begin()
  " call plug#begin('~/.vim/plugged')

  " Make sure you use single quotes

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
  Plug 'flazz/vim-colorschemes'
  Plug 'xolox/vim-colorscheme-switcher'
  Plug 'xolox/vim-misc'
  Plug 'elixir-lang/vim-elixir'
  Plug 'slashmili/alchemist.vim'
  if has('nvim')
    Plug 'f-person/auto-dark-mode.nvim'
  endif
  " Plug 'Valloric/YouCompleteMe', { 'do': './install.py' }
  call plug#end()

  " Install missing plugins
  autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
    \| PlugInstall --sync | source $MYVIMRC
  \| endif

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
  " colorscheme lucid
  if has('macunix')
    let s:apple_style = trim(system('defaults read -g AppleInterfaceStyle 2>/dev/null'))
    if s:apple_style ==# 'Dark'
      let g:lucius_style = 'dark'
    else
      let g:lucius_style = 'light'
    endif
    unlet s:apple_style
  endif
  colorscheme lucius
  " colorscheme obsidian

  if has('nvim')
    lua << EOF
vim.lsp.config('expert', {
  cmd = { 'expert', '--stdio' },
  root_markers = { 'mix.exs', '.git' },
  filetypes = { 'elixir', 'eelixir', 'heex' },
})
vim.lsp.enable('expert')

local ok, auto_dark_mode = pcall(require, 'auto-dark-mode')
if ok then
  auto_dark_mode.setup({
    fallback = 'dark',
    set_dark_mode = function()
      vim.g.lucius_style = 'dark'
      vim.cmd('colorscheme lucius')
    end,
    set_light_mode = function()
      vim.g.lucius_style = 'light'
      vim.cmd('colorscheme lucius')
    end,
  })
end
EOF
  endif


  "Vim-airline
  "===========
  let g:airline_theme='wombat'
  let g:airline_powerline_fonts = 0
  "branch parts
  let g:airline#extensions#branch#enabled = 1
  "seperators
  let g:airline_left_sep = ''
  let g:airline_right_sep = ''
  "modes
  let g:airline_section_b=""
  let g:airline_section_x=""
  let g:airline_section_y=""
  "let g:airline_section_gutter=""
  let g:airline#extensions#whitespace#enabled = 0
  " let g:airline#extensions#tabline#enabled = 1


  " let g:polyglot_disabled = ['elixir']

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
  " set ttyscroll=3 " speed up scrolling
  set ttyfast " Optimize for fast terminal connections
  set lazyredraw " to avoid scrolling problems
  set backspace=indent,eol,start  " Enable backspace in most situations


  """""""""""""""""""
  " => Key bindings "
  """""""""""""""""""
  map <C-n> :NERDTreeToggle<CR>


  """""""""""""""
  " => Triggers "
  """""""""""""""
  augroup neomake_on_save
    autocmd!
    autocmd BufWritePost * if index(['elixir', 'eelixir', 'heex'], &filetype) < 0 | Neomake | endif
  augroup END

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
endif
