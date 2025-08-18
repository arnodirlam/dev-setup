# see https://github.com/romkatv/powerlevel10k/issues/702#issuecomment-626222730
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/arno/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="kennethreitz"
# ZSH_THEME="fishy"
# ZSH_THEME="robbyrussell"
# ZSH_THEME="awesomepanda"
# ZSH_THEME="sorins2"
# ZSH_THEME="agnoster"
ZSH_THEME="powerlevel10k/powerlevel10k"

RPROMPT='$(tf_prompt_info)'
ZSH_THEME_TF_PROMPT_PREFIX=""
ZSH_THEME_TF_PROMPT_SUFFIX=""

# RPROMPT='$(tf_prompt_info)'
# ZSH_THEME_TF_PROMPT_PREFIX="%{$fg_bold[yellow]%}"
# ZSH_THEME_TF_PROMPT_SUFFIX="%{$reset_color%}"


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  asdf
  aws
  brew
  colorize
  docker
  docker-compose
  elixir
  git
  kubectl
#  mise
  per-directory-history
  terraform
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# see https://github.com/zsh-users/zsh-completions
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# Homebrew completions
# ====================
# if type brew &>/dev/null; then
#   FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
# 
#   autoload -Uz compinit
#   compinit
# fi

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/arno_rsa"

# gpg
export GPG_TTY=$(tty)

# Homebrew
# ========
export HOMEBREW_BAT=true
export HOMEBREW_INSTALL_BADGE="✅"
export HOMEBREW_NO_AUTO_UPDATE=true
export HOMEBREW_NO_INSTALL_CLEANUP=true

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="vim ~/.zshrc && source ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias reload="exec $SHELL -l"

alias grbomi='git rebase --interactive origin/$(git_main_branch)'
alias gbdgone='git for-each-ref --format="%(upstream:track) %(refname:short)" | command grep -E "^\[gone\] " | command cut -d" " -f2 | command xargs -n 1 git branch -D'
alias gmm='git merge origin/$(git_main_branch)'
alias gcpn='git cherry-pick --no-commit'
alias gprod="git fetch --all && git log --left-right --graph --cherry-pick --pretty='format:%s (%an, %ar)' origin/production...origin/master"
alias gprodl="git fetch --all && git log --left-right --graph --cherry-pick --pretty='format:%s (%an, %ar) %H' production...origin/master"
alias maat='java -jar /Users/arno/dev/code-maat/target/code-maat-1.1-SNAPSHOT-standalone.jar'

# AWS & Terraform
alias awswmi='aws sts get-caller-identity'
alias tfw='tf workspace select'
alias tfaa='terraform apply -auto-approve'

# asdf
function asdfre() {
  asdf uninstall $@
  asdf install $@
}

# Enable Elixir iex history
export ERL_AFLAGS="-kernel shell_history enabled"


# Elixir
# ======
alias et="iex -S mix test --trace"
alias mfa="mix format_all"
alias me="mix eunit"
alias mct="MIX_ENV=test mix compile"
alias mcft="MIX_ENV=test mix compile --force"
alias mcftw="watchexec -r --wrap-process=session -q -c -i 'tmp/**' -i '.git/**' -e 'ex,exs,eex,leex,heex' -- 'MIX_ENV=test mix compile --force --warnings-as-errors && echo ✅ || echo ❌'"
alias mcw="watchexec -r -q -e 'ex,exs,eex,leex,heex' -E WARNINGS_AS_ERRORS=true -- 'mix compile --warnings-as-errors && echo ✅ || echo ❌'"
alias mcfw="watchexec --debounce 5sec -r -c -e 'ex,exs,eex,leex,heex' -E WARNINGS_AS_ERRORS=true -- 'mix compile --force && echo ✅'"
alias mdlw="watchexec --debounce 5sec -r -c -e 'ex,exs,eex,leex,heex' -E WARNINGS_AS_ERRORS=true -- 'mix dialyzer && echo ✅'"
alias mcrw="watchexec -r -e 'ex,exs,eex,leex,heex' -- 'mix credo && echo ✅ || echo ❌'"
alias mtws="watchexec -o queue -e 'ex,exs,eex,leex,heex' -- mix test --stale"
alias mt_="mix test --max-cases 2"
alias mta="mix assets.build && mix test --include feature --max-cases 1"
alias mtf_="mix test --only feature --max-cases 1"
alias mtfw="watchexec -o queue --wrap-process=session -q -e 'ex,exs,eex,leex,heex,js' -- mix assets.build && mix test --only feature --max-cases 1"
alias mtf1="mix test --max-cases 2 --seed 0 --max-failures=1"
alias mtw1="watchexec -o queue --wrap-process=session -q -e 'ex,exs,eex,leex,heex,js' -- mix test --seed 0 --max-failures 1 --max-cases 2 --warnings-as-errors"
alias mtwf="watchexec -o queue --wrap-process=session -q -e 'ex,exs,eex,leex,heex,js' -- mix test --failed --seed 0 && mix test --seed 0 --max-cases 2"
function mtw_() {
  watchexec -o queue --wrap-process=session -q -i 'tmp/**' -i '.git/**' -e 'ex,exs,eex,leex,heex,js' -- "mix test --max-cases 2 --warnings-as-errors $@ && echo ✅ || echo ❌"
}
function mtwf1() {
  watchexec -o queue --wrap-process=session -q -i 'tmp/**' -i '.git/**' -i '**/priv/static/assets/**' -e 'ex,exs,eex,leex,heex,js' -- "mix test --failed --seed 0 --max-failures 1 --max-cases 1 && mix test --max-failures 1 --max-cases 1 --warnings-as-errors $@ && echo ✅ || echo ❌"
}
function mtawf() {
  watchexec -o queue --wrap-process=session -q -i 'tmp/**' -i '.git/**' -e 'ex,exs,eex,leex,heex,js' -- "mix assets.build && mix test --include feature --failed --seed 0 --max-cases 1 && mix test --include feature --max-cases 1 $@ && echo ✅ || echo ❌"
}
function mtfwf() {
  watchexec -o queue --wrap-process=session -q -i 'tmp/**' -i '.git/**' -e 'ex,exs,eex,leex,heex,js' -- "mix assets.build && mix test --only feature --failed --seed 0 --max-cases 1 && mix test --only feature --max-cases 1 $@ && echo ✅ || echo ❌"
}
function mtawf1() {
  watchexec -o queue --wrap-process=session -q -i 'tmp/**' -i '.git/**' -e 'ex,exs,eex,leex,heex,js' -- "mix assets.build && mix test --include feature --failed --seed 0 --max-failures 1 --max-cases 1 && mix test --include feature --max-cases 1 $@ && echo ✅ || echo ❌"
}
function mtfwf1() {
  watchexec -o queue --wrap-process=session -q -i 'tmp/**' -i '.git/**' -e 'ex,exs,eex,leex,heex,js' -- "mix assets.build && mix test --only feature --failed --seed 0 --max-failures 1 --max-cases 1 && mix test --only feature --max-cases 1 $@ && echo ✅ || echo ❌"
}
function mtwf1t() {
  watchexec -o queue --wrap-process=session -q -i 'tmp/**' -i '.git/**' -e 'ex,exs,eex,leex,heex' -- "(cp tmp/.tool-versions . && mix format && mix test --failed --seed 0 --max-failures 1 --max-cases 2 && mix test --seed 0 --max-failures 1 --max-cases 2 --warnings-as-errors $@ && echo ✅ || echo ❌); git checkout .tool-versions"
}
alias mtwf1a="watchexec -o queue --wrap-process=session -i 'tmp/**' -i '.git/**' -e 'ex,exs,eex,leex,heex' -- 'mix test --failed --seed 0 --max-failures 1 && WARNINGS_AS_ERRORS=true mix test --seed 0 --max-failures 1 && MIX_ENV=test WARNINGS_AS_ERRORS=true mix compile --force && echo ✅'"
alias mtwf12="mix test.watch --failed --max-failures 1 --max-cases 2"
alias wdocs="open doc/index.html; watchexec -o queue --wrap-process=session -e 'md,ex,exs' -- 'mix docs -f html'"
alias wtf="watchexec -o queue -e 'tf' -c -- terraform plan"

# Erlang build flags
# ==================
export CFLAGS="-O2 -g -fno-stack-check"
export KERL_CONFIGURE_OPTIONS="--disable-hipe --with-ssl=$(brew --prefix openssl@3) --with-wx-config=$(brew --prefix wxwidgets)/bin/wx-config --with-odbc=$(brew --prefix unixodbc)" 
export KERL_BUILD_DOCS=yes
export CPPFLAGS="-I$(brew --prefix unixodbc)/include"
export LDFLAGS="-L$(brew --prefix unixodbc)/lib"

# Docker
# ======
alias dblx64="docker buildx build --platform linux/amd64"

# Go
# ==
export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

# imagemaguick@6
# export PATH="$PATH:/opt/homebrew/opt/imagemagick@6/bin"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

