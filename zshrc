autoload -U compinit
compinit

autoload -U colors
colors

test -e $HOME/.nvm/nvm.sh && . $HOME/.nvm/nvm.sh

timeout () {
  perl -e 'use Time::HiRes qw( usleep ualarm gettimeofday tv_interval ); ualarm 50000; exec @ARGV' "$@";
}

git_untracked_count() {
  count=`echo $(timeout git ls-files --other --exclude-standard | wc -l)`
  if [ $count -eq 0 ]; then return; fi
  echo " %{$fg_bold[yellow]%}?%{$fg_no_bold[black]%}:%{$reset_color$fg[yellow]%}$count%{$reset_color%}"
}

git_modified_count() {
  count=`echo $(timeout git ls-files -md | wc -l)`
  if [ $count -eq 0 ]; then return; fi
  echo " %{$fg_bold[red]%}M%{$fg_no_bold[black]%}:%{$reset_color$fg[red]%}$count%{$reset_color%}"
}

git_staged_count() {
  count=`echo $(timeout git diff-index --cached --name-only HEAD 2>/dev/null | wc -l)`
  if [ $count -eq 0 ]; then return; fi
  echo " %{$fg_bold[green]%}S%{$fg_no_bold[black]%}:%{$reset_color$fg[green]%}$count%{$reset_color%}"
}

git_branch() {
  branch=$(git symbolic-ref HEAD --quiet 2> /dev/null)
  if [ -z $branch ]; then
    echo "%{$fg[yellow]%}$(git rev-parse --short HEAD)%{$reset_color%}"
  else
    echo "%{$fg[green]%}${branch#refs/heads/}%{$reset_color%}"
  fi
}

git_remote_difference() {
  branch=$(git symbolic-ref HEAD --quiet)
  if [ -z $branch ]; then return; fi

  remote=$(git remote show)
  ahead_by=`echo $(git log --oneline $remote/${branch#refs/heads/}..HEAD 2> /dev/null | wc -l)`
  behind_by=`echo $(git log --oneline HEAD..$remote/${branch#refs/heads/} 2> /dev/null | wc -l)`

  output=""
  if [ $ahead_by -gt 0 ]; then output="$output%{$fg_bold[white]%}↑%{$reset_color%}$ahead_by"; fi
  if [ $behind_by -gt 0 ]; then output="$output%{$fg_bold[white]%}↓%{$reset_color%}$behind_by"; fi

  echo $output
}

git_user() {
  user=$(git config user.name)
  if [ -z $user ]; then
    echo "%{$fg_bold[red]%}no user%{$fg[black]%}@%{$reset_color%}"
  else
    echo "$user%{$fg[black]%}@%{$reset_color%}"
  fi
}

in_git_repo() {
  if [[ -d .git ]]; then
    echo 0
  else
    echo $(git rev-parse --git-dir > /dev/null 2>&1; echo $?)
  fi
}

git_prompt_info() {
  if [[ $(in_git_repo) -gt 0 ]]; then return; fi
  print " $(git_user)$(git_branch)$(git_remote_difference)$(git_staged_count)$(git_modified_count)$(git_untracked_count) "
}

simple_git_prompt_info() {
  ref=$($(which git) symbolic-ref HEAD 2> /dev/null) || return
  user=$($(which git) config user.name 2> /dev/null)
  echo " (${user}@${ref#refs/heads/})"
}

set -o emacs
setopt prompt_subst
setopt HIST_IGNORE_DUPS
setopt APPEND_HISTORY
setopt SHARE_HISTORY
#### zsh history #### {
HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

export HISTSIZE=20000

export LOCALE="en_US.UTF-8"
export LANG="en_US.UTF-8"

export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
export PROMPT='%{$fg_no_bold[green]%}%m:%{$fg_no_bold[blue]%}%~%{$fg_no_bold[green]%}$(git_prompt_info)%{$reset_color%}%# '

export EDITOR=nvim

if [[ `uname` == 'Linux' ]]; then
  export JAVA_HOME="/usr"
else
  export JAVA_HOME="/Library/Java/Home"
fi

export PATH="/usr/local/share/python":$PATH
export PATH="/usr/local/share/npm/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/ruby/bin:$PATH"
export PATH="$PATH:/usr/local/pear/bin"
export PATH="$PATH:$SYSTEM_SCRIPTS/bin"
export PATH="$PATH:$EC2_HOME/bin:$EC2_AMI_HOME/bin"
export PATH="$PATH:/usr/local/Cellar/python/2.7.2/bin"
export PATH="$PATH:/Applications/wkhtmltopdf.app/Contents/MacOS"
export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/9.3/bin"
export PATH="$PATH:./bin"

export TERM=xterm-256color

autoload edit-command-line
zle -N edit-command-line
bindkey '^X^e' edit-command-line

stty stop undef
stty start undef

_rake () {
  if [ -f Rakefile ]; then
    compadd `rake --silent --tasks | cut -d " " -f 2`
  fi
}

compdef _rake rake

_cap () {
  if [ -f Capfile ]; then
    compadd `cap -vT | grep '^cap' | cut -d ' ' -f 2`
  fi
}

compdef _cap cap

source ~/.aliases
source /usr/local/opt/nvm/nvm.sh


[[ -s ~/.zshenv_personal ]] && source ~/.zshenv_personal

[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.cabal/bin:$PATH"
bindkey '^R' history-incremental-search-backward

function replace () {
  grep -R -l $1 ${3-.} | xargs sed -i '' "s/$1/$2/g"
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f'
