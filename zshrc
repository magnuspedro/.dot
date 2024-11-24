export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="spaceship"

plugins=(git)

source $ZSH/oh-my-zsh.sh

eval $(/opt/homebrew/bin/brew shellenv)

. /opt/homebrew/opt/asdf/libexec/asdf.sh
export GOROOT=~/.asdf/installs/golang/1.21.4/go

alias rmt="cd /Users/magnus/iCloud/Documents/Studies/spring-rmt"

[ -f "/Users/magnus/.ghcup/env" ] && source "/Users/magnus/.ghcup/env" # ghcup-env

if [ "$TMUX" = "" ]; then tmux; fi


